defmodule PodcastsApi.FeedController do
  use PodcastsApi.Web, :controller

  alias PodcastsApi.Feed
  plug Guardian.Plug.EnsureAuthenticated, handler: PodcastsApi.AuthErrorHandler

  require Logger
  import SweetXml

  def index(conn, _params) do
    feeds = Repo.all(PodcastsApi.Feed)
    Logger.info "feeds: "
    conn
    |> render("index.json-api", data: feeds)
  end

  def create(conn, %{"data" => %{
    "type" => "feeds",
    "attributes" => %{
      "url" => source_url
    }
  }}) do

    # text = ~s{<?xml version="1.0" encoding="UTF-8"?> <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:bitlove="http://bitlove.org" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:fh="http://purl.org/syndication/history/1.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:psc="http://podlove.org/simple-chapters">   <channel>     <title>Freak Show</title>     <link>http://freakshow.fm</link>    <description>Menschen! Technik! Sensationen!</description>    <lastBuildDate>Fri, 13 Jan 2017 14:20:30 +0000</lastBuildDate>    <image>       <url>http://freakshow.fm/wp-content/cache/podlove/04/662a9d4edcf77ea2abe3c74681f509/freak-show_original.jpg</url>       <title>Freak Show</title>       <link>http://freakshow.fm</link>    </image>    <atom:link href="http://freakshow.fm/feed/m4a?paged=2" rel="self" title="Freak Show (MPEG-4 AAC Audio)" type="application/rss+xml"/>    <atom:link href="http://freakshow.fm/feed/mp3" rel="alternate" title="Freak Show (MP3 Audio)" type="application/rss+xml"/>    <atom:link href="http://freakshow.fm/feed/oga" rel="alternate" title="Freak Show (Ogg Vorbis Audio)" type="application/rss+xml"/>     <atom:link href="http://freakshow.fm/feed/opus" rel="alternate" title="Freak Show (Ogg Opus Audio)" type="application/rss+xml"/>    <atom:link href="http://freakshow.fm/feed/m4a?paged=3" rel="next"/>     <atom:link href="http://freakshow.fm/feed/m4a" rel="prev"/>     <atom:link href="http://freakshow.fm/feed/m4a" rel="first"/>    <atom:link href="http://freakshow.fm/feed/m4a?paged=7" rel="last"/>     <language>de-DE</language>    <atom:link href="http://metaebene.superfeedr.com" rel="hub"/>     <fyyd:verify xmlns:fyyd="https://fyyd.de/fyyd-ns/">nb7iw45eqiWaHwbkg1ncdT3b2ynd86i5v4wlfZp2</fyyd:verify>     <atom:link href="https://flattr.com/submit/auto?user_id=timpritlove&amp;url=http%3A%2F%2Ffreakshow.fm%2F&amp;language=de_DE&amp;category=audio&amp;title=Freak+Show&amp;description=Menschen%21+Technik%21+Sensationen%21&amp;tags=podcast%2C+freakshow%2C+tim+pritlove%2C+metaebene" rel="payment" title="Flattr this!" type="text/html"/>     <atom:contributor>      <atom:name>Tim Pritlove</atom:name>       <atom:uri>http://tim.pritlove.org/</atom:uri>     </atom:contributor>     <generator>Podlove Podcast Publisher v2.5.0.build284</generator>    <itunes:author>Metaebene Personal Media - Tim Pritlove</itunes:author>    <itunes:summary>Die muntere Talk Show um Leben mit Technik, das Netz und Technikkultur. Bisweilen Apple-lastig aber selten einseitig. Wir leben und lieben Technologie und reden darüber. Mit Tim, hukl, roddi, Clemens und Denis. Freak Show hieß irgendwann mal mobileMacs.</itunes:summary>    <itunes:category text="Technology">       <itunes:category text="Tech News"/>     </itunes:category>    <itunes:category text="Society &amp; Culture"/>     <itunes:category text="Technology">       <itunes:category text="Gadgets"/>     </itunes:category>    <itunes:owner>      <itunes:name>Tim Pritlove</itunes:name>       <itunes:email>freakshow@metaebene.me</itunes:email>     </itunes:owner>     <itunes:image href="http://freakshow.fm/wp-content/cache/podlove/04/662a9d4edcf77ea2abe3c74681f509/freak-show_original.jpg"/>     <itunes:subtitle>Menschen! Technik! Sensationen!</itunes:subtitle>    <itunes:block>no</itunes:block>     <itunes:explicit>no</itunes:explicit>     <atom:link href="https://flattr.com/submit/auto?user_id=timpritlove&amp;language=de_DE&amp;url=http%3A%2F%2Ffreakshow.fm&amp;title=Freak+Show&amp;description=Menschen%21+Technik%21+Sensationen%21" rel="payment" title="Flattr this!" type="text/html"/>  </channel> </rss>}
    Logger.info "before parse..."
    # title = text |> xpath(~x"//channel/title/text()"S)

    case HTTPoison.get(source_url, [], [ ssl: [{:versions, [:'tlsv1.2']}] ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # Logger.info body
        parsed = body
        |> xmap(
          title: ~x"//channel/title/text()"S,
          description: ~x"//channel/description/text()"S,
          link: ~x"//channel/link/text()"S,
          image_url: ~x"//channel/image/url/text()"S)
        |> Map.put(:source_url, source_url)
        
        changeset = Feed.changeset %Feed{}, parsed
        case Repo.insert changeset do
          {:ok, feed} ->
            conn
            |> put_status(:created)
            |> render(PodcastsApi.FeedView, "show.json-api", feed: feed)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(PodcastsApi.ChangesetView, "error.json-api", changeset: changeset)
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.ChangesetView,
          "error.json-api",
          reason: "not found")
      {:error, %HTTPoison.Error{reason: reason}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(PodcastsApi.ChangesetView, "error.json-api", reason: reason)

    end

  end
end
