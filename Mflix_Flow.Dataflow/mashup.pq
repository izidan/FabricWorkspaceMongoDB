[DefaultOutputDestinationSettings = [DestinationDefinition = [Kind = "Reference", QueryName = "DefaultDestination", IsNewTarget = true], UpdateMethod = [Kind = "Replace"], DestinationTypeSettings = [Kind = "Table"]], StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "movies_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared movies = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "0c648672-dabb-48fb-9451-fb7d3bd859a2"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "movies", ItemKind = "Table"]}[Data],
  #"Replace nan" = Table.TransformColumns(#"Navigation 2", {
    {"plot", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"genres", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"cast", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"poster", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"fullplot", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"languages", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"directors", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"rated", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"awards", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"imdb", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"countries", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"tomatoes", each if _ = "nan" then null else Text.Clean(_), type nullable text},
    {"writers", each if _ = "nan" then null else Text.Clean(_), type nullable text}}),
  #"Parse json" = Table.TransformColumns(#"Replace nan", {{"awards", each Json.Document(_), type nullable any}, {"imdb", each Json.Document(_), type nullable any},{"tomatoes", each Json.Document(_??"{}"), type nullable any}}),
  #"Expanded awards" = Table.ExpandRecordColumn(#"Parse json", "awards", {"wins", "nominations", "text"}, {"awards.wins", "awards.nominations", "awards.text"}),
  #"Expanded imdb" = Table.ExpandRecordColumn(#"Expanded awards", "imdb", {"rating", "votes", "id"}, {"imdb.rating", "imdb.votes", "imdb.id"}),
  #"Expanded tomatoes" = Table.ExpandRecordColumn(#"Expanded imdb", "tomatoes", {"website", "viewer", "dvd", "critic", "lastUpdated", "consensus", "rotten", "production", "fresh"}, {"tomatoes.website", "tomatoes.viewer", "tomatoes.dvd", "tomatoes.critic", "tomatoes.lastUpdated", "tomatoes.consensus", "tomatoes.rotten", "tomatoes.production", "tomatoes.fresh"}),
  #"Expanded tomatoes.viewer" = Table.ExpandRecordColumn(#"Expanded tomatoes", "tomatoes.viewer", {"rating", "numReviews", "meter"}, {"tomatoes.viewer.rating", "tomatoes.viewer.numReviews", "tomatoes.viewer.meter"}),
  #"Expanded tomatoes.critic" = Table.ExpandRecordColumn(#"Expanded tomatoes.viewer", "tomatoes.critic", {"rating", "numReviews", "meter"}, {"tomatoes.critic.rating", "tomatoes.critic.numReviews", "tomatoes.critic.meter"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded tomatoes.critic", {{"awards.wins", Int64.Type}, {"awards.nominations", Int64.Type}, {"awards.text", type text}, {"lastupdated", type datetime}, {"imdb.rating", type number}, {"imdb.votes", Int64.Type}, {"imdb.id", Int64.Type}, {"tomatoes.website", type text}, {"tomatoes.viewer.rating", type number}, {"tomatoes.viewer.numReviews", Int64.Type}, {"tomatoes.viewer.meter", Int64.Type}, {"tomatoes.dvd", type datetime}, {"tomatoes.critic.rating", type number}, {"tomatoes.critic.numReviews", Int64.Type}, {"tomatoes.critic.meter", Int64.Type}, {"tomatoes.consensus", type text}, {"tomatoes.rotten", Int64.Type}, {"tomatoes.production", type text}, {"tomatoes.fresh", Int64.Type}, {"tomatoes.lastUpdated", type datetime}}),
  #"Cleaned text" = Table.TransformColumns(#"Changed column type", {{"genres", each Text.Replace(Text.Replace(Text.Replace(_,"[",""),"]",""),"""",""), type nullable text},{"cast", each Text.Replace(Text.Replace(Text.Replace(Text.Replace(_,"[",""),"]",""),"""",""),"\u00e8","è"), type nullable text},{"languages", each Text.Replace(Text.Replace(Text.Replace(_,"[",""),"]",""),"""",""), type nullable text},{"directors", each Text.Replace(Text.Replace(Text.Replace(Text.Replace(_,"[",""),"]",""),"""",""),"\u00e8","è"), type nullable text},{"countries", each Text.Replace(Text.Replace(Text.Replace(_,"[",""),"]",""),"""",""), type nullable text},{"writers", each Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.Replace(_,"[",""),"]",""),"\""","'"),"""",""),"\u00e8","è"), type nullable text}})
in
  #"Cleaned text";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "theaters_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared theaters = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "0c648672-dabb-48fb-9451-fb7d3bd859a2"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "theaters", ItemKind = "Table"]}[Data],
  #"Parse location" = Table.TransformColumns(#"Navigation 2", {{"location", each Json.Document(_),type nullable any}}),
  #"Expanded location" = Table.ExpandRecordColumn(#"Parse location", "location", {"address", "geo"}, {"address", "geo"}),
  #"Expanded address" = Table.ExpandRecordColumn(#"Expanded location", "address", {"street1","street2", "city", "state", "zipcode"}, {"street1", "street2", "city", "state", "zipcode"}),
  #"Expanded geo" = Table.ExpandRecordColumn(#"Expanded address", "geo", {"type", "coordinates"}, {"type", "coordinates"}),
  #"Added latitude" = Table.TransformColumnTypes(Table.AddColumn(#"Expanded geo", "latitude", each List.Last([coordinates])), {{"latitude", type number}}),
  #"Added longitude" = Table.TransformColumnTypes(Table.AddColumn(#"Added latitude", "longitude", each List.First([coordinates])), {{"longitude", type number}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Added longitude", {{"street1", type text}, {"city", type text}, {"state", type text}, {"zipcode", type text}, {"street2", type text}}),
  #"Removed columns" = Table.RemoveColumns(#"Changed column type", {"type", "coordinates"})
in
  #"Removed columns";
shared theaters_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "0c648672-dabb-48fb-9451-fb7d3bd859a2"]}[Data],
  TableNavigation = Navigation_2{[Id = "theatres", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared movies_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "0c648672-dabb-48fb-9451-fb7d3bd859a2"]}[Data],
  TableNavigation = Navigation_2{[Id = "movies_ratings", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared DefaultDestination = Lakehouse.Contents([EnableFolding = false]){[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data]{[lakehouseId = "0c648672-dabb-48fb-9451-fb7d3bd859a2"]}[Data];
