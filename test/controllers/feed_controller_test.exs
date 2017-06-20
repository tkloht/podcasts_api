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

  def create_test_feed_with_episodes() do
    Enum.each ["test1", "test2", "test3"], fn name -> 
      Repo.insert! %Feed{
        source_url: "http://feeds.metaebene.me/freakshow/m4a",
        title: "freakshow",
        description: name,
        link: "test",
        image_url: "test",
        episodes: [%{
          title: "test_episode", 
          link: "http://test.com",
          pubDate: Timex.parse!("Thu, 23 Feb 2017 02:11:53 +0000", "{RFC822}"),
        }]
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

  describe "show" do
    test "show feed if available", %{conn: conn} do
      create_test_feed
      feed = Repo.get_by(Feed, %{description: "test1"})
      conn = get conn, feed_path(conn, :show, feed.id)
      %{
        "attributes" => %{
          "description" => description
        },
      } = json_response(conn, 200)["data"]
      assert description == "test1"
    end

    test "show feed with episodes if feed has episodes", %{conn: conn} do
      create_test_feed_with_episodes
      feed = Repo.get_by(Feed, %{description: "test1"})
      conn = get conn, feed_path(conn, :show, feed.id)

      %{
        "attributes" => %{
          "description" => description
        },
        "relationships" => %{
          "episodes" => episodes
        }
      } = json_response(conn, 200)["data"]
      assert description == "test1"
      assert episodes != nil
      refute Enum.empty? episodes
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

    test "should return feed with episodes after adding valid feed", %{conn: conn} do
      use_cassette "valid_freakshow" do
      conn = post conn, feed_path(conn, :create), build_data("https://feeds.metaebene.me/freakshow/m4a")
      %{"data" => %{
        "attributes" => %{
          "title" => title,
        },
        "relationships" => %{
          "episodes" => episodes,
        }
      }} =  json_response(conn, 201)
      refute title == nil
      refute episodes == nil
      refute Enum.empty? episodes
      end      
    end
  end

end
