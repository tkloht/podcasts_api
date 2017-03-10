defmodule PodcastsApi.FeedControllerTest do
  use PodcastsApi.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias PodcastsApi.Feed
  import PodcastsApi.FeedController

  def create_test_feed() do
    Enum.each ["test1", "test2", "test3"], fn name -> 
      Repo.insert! %Feed{
        source_url: "http://feeds.metaebene.me/freakshow/m4a",
        title: "freakshow",
        description: name,
        link: "test",
        image_url: "test"
      }
    end
  end

  def get_fixture(fixture_name) do
    app_root = Application.app_dir(:podcasts_api, "priv")
    path = Path.relative_to_cwd(Path.join([app_root, "fixtures", fixture_name]))
    File.read! path
  end

  setup_all do
    HTTPoison.start
  end

  setup %{conn: conn} do
    user = Repo.insert! %PodcastsApi.User{}
    { :ok, jwt, _ } = Guardian.encode_and_sign(user, :token)
    conn = conn
    |> put_req_header("content-type", "application/vnd.api+json")
    |> put_req_header("authorization", "Bearer #{jwt}")
 
    {:ok, %{conn: conn, user: user}}
  end

  describe "index" do
    test "show empty list if no feed available", %{conn: conn} do
      conn = get conn, feed_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end

    test "lists all feeds on index",  %{conn: conn} do
      create_test_feed
      conn = get conn, feed_path(conn, :index)
      assert Enum.count(json_response(conn, 200)["data"]) == 3
    end
  end

  describe "create" do

    defp build_data (url) do
      %{
        "data" => %{
          "type" => "feeds",
          "attributes" => %{
            "url" => url
          }
        }
      }
    end

    test "should show no-xml-error if document at supplied url is not valid xml" , %{conn: conn} do
      use_cassette "example_no_xml" do
        conn = post(conn, feed_path(conn, :create), build_data("https://freakshow.fm"))
        %{"errors" => [%{
            "code" => code,
            "title" => title
          }]
        } = json_response(conn, 422)
        assert code == 422
        assert title == "No xml"
      end
    end
    
    test "should show no-feed-error if document at supplied url is not a valid feed" , %{conn: conn} do
      use_cassette "no_feed" do
        conn = post(conn, feed_path(conn, :create), build_data("https://www.w3schools.com/xml/note.xml"))
        %{"errors" => [%{
            "code" => code,
            "title" => title
          }]
        } = json_response(conn, 422)
        assert code == 422
        assert title == "No feed"
      end
    end

    # test "should show not-found-error if attributes.url is not found", %{conn: conn} do
    #   create_test_feed
    #   conn = post conn, feed_path(conn, :create), build_data("http://invalid_url.com")
    #   assert json_response(conn, 404)
    # end

    test "should return status 201 (created) if attributes.url is valid feed", %{conn: conn} do
      use_cassette "valid_freakshow" do
        conn = post conn, feed_path(conn, :create), build_data("https://feeds.metaebene.me/freakshow/m4a")
        assert json_response(conn, 201)
      end
    end

    test "should insert a feed into the db" , %{conn: conn} do
      use_cassette "valid_freakshow" do
        conn = post conn, feed_path(conn, :create), build_data("https://feeds.metaebene.me/freakshow/m4a")
        assert json_response(conn, 201)

        assert Repo.get_by(Feed, %{source_url: "https://feeds.metaebene.me/freakshow/m4a"})
      end
    end

    test "should insert episodes into the db", %{conn: conn} do
      use_cassette "valid_freakshow" do
        conn = post conn, feed_path(conn, :create), build_data("https://feeds.metaebene.me/freakshow/m4a")
        assert json_response(conn, 201)

        feed = Feed
        |> Repo.get_by(%{source_url: "https://feeds.metaebene.me/freakshow/m4a"})
        |> Repo.preload(:episodes)
        refute feed.episodes == nil
        refute Enum.empty?(feed.episodes)
      end
    end

  end

  describe "parseFeed" do
    test "parses valid feed head correctly" do
      source_url = "test"
      feed_body = get_fixture "valid_freakshow.xml"
      {:ok, parsed} = parseFeed(source_url, feed_body)
      assert parsed.description == "Menschen! Technik! Sensationen!"
      assert parsed.image_url == "http://freakshow.fm/wp-content/cache/podlove/04/662a9d4edcf77ea2abe3c74681f509/freak-show_original.jpg"
      assert parsed.link == "http://freakshow.fm"
      assert parsed.title == "Freak Show"
      assert parsed.source_url == "test"
    end

    test "parsed valid feed has a list of episodes" do
      source_url = "test"
      feed_body = get_fixture "valid_freakshow.xml"
      {:ok, parsed} = parseFeed(source_url, feed_body)
      assert is_list parsed.episodes
      refute Enum.empty?(parsed.episodes)
    end

    test "each parsed episode has title, guid, enclosure" do
      required = [:title, :link, :pubDate, :enclosure]
      feed_body = get_fixture "valid_freakshow.xml"
      {:ok, parsed} = parseFeed("test", feed_body)
      Enum.each(parsed.episodes, fn episode ->
        assert episode[:title] != nil
        Enum.each(required, fn field ->
          refute episode[field] == nil
        end)
      end)
    end

    test "returns no-feed error if not a valid feed" do
      source_url = "test"
      feed_body = ~s{not a feed, not an xml}
      assert parseFeed(source_url, feed_body) == {:error, :no_xml}
    end

    test "return no-feed-error if xml is no feed" do
      source_url = "test"
      feed_body = ~s{<?xml version="1.0" encoding="UTF-8"?> <kkllirss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:bitlove="http://bitlove.org" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:fh="http://purl.org/syndication/history/1.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:psc="http://podlove.org/simple-chapters">   <channel>     <title>Freak Show</title>     <link>http://freakshow.fm</link>    <description>Menschen! Technik! Sensationen!</description>    <lastBuildDate>Fri, 13 Jan 2017 14:20:30 +0000</lastBuildDate>    <image>       <url>http://freakshow.fm/wp-content/cache/podlove/04/662a9d4edcf77ea2abe3c74681f509/freak-show_original.jpg</url>       <title>Freak Show</title>       <link>http://freakshow.fm</link>    </image>    <atom:link href="http://freakshow.fm/feed/m4a?paged=2" rel="self" title="Freak Show (MPEG-4 AAC Audio)" type="application/rss+xml"/>    <atom:link href="http://freakshow.fm/feed/mp3" rel="alternate" title="Freak Show (MP3 Audio)" type="application/rss+xml"/>    <atom:link href="http://freakshow.fm/feed/oga" rel="alternate" title="Freak Show (Ogg Vorbis Audio)" type="application/rss+xml"/>     <atom:link href="http://freakshow.fm/feed/opus" rel="alternate" title="Freak Show (Ogg Opus Audio)" type="application/rss+xml"/>    <atom:link href="http://freakshow.fm/feed/m4a?paged=3" rel="next"/>     <atom:link href="http://freakshow.fm/feed/m4a" rel="prev"/>     <atom:link href="http://freakshow.fm/feed/m4a" rel="first"/>    <atom:link href="http://freakshow.fm/feed/m4a?paged=7" rel="last"/>     <language>de-DE</language>    <atom:link href="http://metaebene.superfeedr.com" rel="hub"/>     <fyyd:verify xmlns:fyyd="https://fyyd.de/fyyd-ns/">nb7iw45eqiWaHwbkg1ncdT3b2ynd86i5v4wlfZp2</fyyd:verify>     <atom:link href="https://flattr.com/submit/auto?user_id=timpritlove&amp;url=http%3A%2F%2Ffreakshow.fm%2F&amp;language=de_DE&amp;category=audio&amp;title=Freak+Show&amp;description=Menschen%21+Technik%21+Sensationen%21&amp;tags=podcast%2C+freakshow%2C+tim+pritlove%2C+metaebene" rel="payment" title="Flattr this!" type="text/html"/>     <atom:contributor>      <atom:name>Tim Pritlove</atom:name>       <atom:uri>http://tim.pritlove.org/</atom:uri>     </atom:contributor>     <generator>Podlove Podcast Publisher v2.5.0.build284</generator>    <itunes:author>Metaebene Personal Media - Tim Pritlove</itunes:author>    <itunes:summary>Die muntere Talk Show um Leben mit Technik, das Netz und Technikkultur. Bisweilen Apple-lastig aber selten einseitig. Wir leben und lieben Technologie und reden darüber. Mit Tim, hukl, roddi, Clemens und Denis. Freak Show hieß irgendwann mal mobileMacs.</itunes:summary>    <itunes:category text="Technology">       <itunes:category text="Tech News"/>     </itunes:category>    <itunes:category text="Society &amp; Culture"/>     <itunes:category text="Technology">       <itunes:category text="Gadgets"/>     </itunes:category>    <itunes:owner>      <itunes:name>Tim Pritlove</itunes:name>       <itunes:email>freakshow@metaebene.me</itunes:email>     </itunes:owner>     <itunes:image href="http://freakshow.fm/wp-content/cache/podlove/04/662a9d4edcf77ea2abe3c74681f509/freak-show_original.jpg"/>     <itunes:subtitle>Menschen! Technik! Sensationen!</itunes:subtitle>    <itunes:block>no</itunes:block>     <itunes:explicit>no</itunes:explicit>     <atom:link href="https://flattr.com/submit/auto?user_id=timpritlove&amp;language=de_DE&amp;url=http%3A%2F%2Ffreakshow.fm&amp;title=Freak+Show&amp;description=Menschen%21+Technik%21+Sensationen%21" rel="payment" title="Flattr this!" type="text/html"/>  </channel> </kkllirss>}
      assert parseFeed(source_url, feed_body) == {:error, :no_feed}
    end

  end


end
