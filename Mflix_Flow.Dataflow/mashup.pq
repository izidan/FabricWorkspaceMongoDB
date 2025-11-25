[DefaultOutputDestinationSettings = [DestinationDefinition = [Kind = "Reference", QueryName = "DefaultDestination", IsNewTarget = true], UpdateMethod = [Kind = "Replace"], DestinationTypeSettings = [Kind = "Table"]], StagingDefinition = [Kind = "FastCopy"]]
section Section1;
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
  #"Changed column type" = Table.TransformColumnTypes(#"Added longitude", {{"street1", type text}, {"city", type text}, {"state", type text}, {"zipcode", type text}, {"street2", type text}, {"theaterId", type text}}),
  #"Removed columns" = Table.RemoveColumns(#"Changed column type", {"type", "coordinates"})
in
  #"Removed columns";
shared DefaultDestination = Lakehouse.Contents([EnableFolding = false]){[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data]{[lakehouseId = "0c648672-dabb-48fb-9451-fb7d3bd859a2"]}[Data];
[BindToDefaultDestination = true]
shared shows = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "0c648672-dabb-48fb-9451-fb7d3bd859a2"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "movies", ItemKind = "Table"]}[Data],
  #"Replace nan" = Table.TransformColumns(#"Navigation 2", {
    {"plot", each if _ = "nan" or _ = "" then null else Text.Clean(_), type nullable text},
    {"genres", each if _ = "nan" or _ = "" then null else Text.Clean(_), type nullable text},
    {"cast", each if _ = "nan" or _ = "" then null else Text.Clean(_), type nullable text},
    {"poster", each if _ = "nan" or _ = "" then null else Text.Clean(_), type nullable text},
    {"fullplot", each if _ = "nan" or _ = "" then null else Text.Clean(_), type nullable text},
    {"languages", each if _ = "nan" or _ = "" then "[]" else Text.Clean(_), type nullable text},
    {"directors", each if _ = "nan" or _ = "" then "[]" else Text.Clean(_), type nullable text},
    {"rated", each if _ = "nan" or _ = "" then null else Text.Clean(_), type nullable text},
    {"awards", each if _ = "nan" or _ = "" then null else Text.Clean(_), type nullable text},
    {"imdb", each if _ = "nan" or _ = "" then null else Text.Clean(_), type nullable text},
    {"countries", each if _ = "nan" or _ = "" then "[]" else Text.Clean(_), type nullable text},
    {"tomatoes", each if _ = "nan" or _ = "" then null else Text.Clean(_), type nullable text},
    {"writers", each if _ = "nan" or _ = "" then "[]" else Text.Clean(_), type nullable text}}),
  #"Replaced value" = Table.ReplaceValue(#"Replace nan", "\u00e8", "è", Replacer.ReplaceText, {"cast", "directors", "writers"}),
  #"Parse json" = Table.TransformColumns(#"Replaced value", {{"awards", each Json.Document(_), type nullable any}, {"imdb", each Json.Document(_), type nullable any},{"tomatoes", each Json.Document(_??"{}"), type nullable any},{"genres", each Json.Document(_), type nullable any},{"cast", each Json.Document(_), type nullable any},{"languages", each Json.Document(_), type nullable any},{"directors", each Json.Document(_), type nullable any},{"countries", each Json.Document(_), type nullable any},{"writers", each Json.Document(_), type nullable any}}),
  #"Expanded awards" = Table.ExpandRecordColumn(#"Parse json", "awards", {"wins", "nominations", "text"}, {"awards.wins", "awards.nominations", "awards.text"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded awards", {{"awards.wins", Int64.Type}, {"awards.nominations", Int64.Type}, {"awards.text", type text}, {"lastupdated", type datetime}})
in
  #"Changed column type";
[BindToDefaultDestination = true]
shared ratings = let
  Source = shows,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "imdb", "tomatoes"}),
  #"Expanded imdb" = Table.ExpandRecordColumn(#"Removed other columns", "imdb", {"rating", "votes", "id"}, {"imdb.rating", "imdb.votes", "imdb.id"}),
  #"Expanded tomatoes" = Table.ExpandRecordColumn(#"Expanded imdb", "tomatoes", {"website", "viewer", "dvd", "critic", "boxOffice", "consensus", "rotten", "production", "lastUpdated", "fresh"}, {"tomatoes.website", "tomatoes.viewer", "tomatoes.dvd", "tomatoes.critic", "tomatoes.boxOffice", "tomatoes.consensus", "tomatoes.rotten", "tomatoes.production", "tomatoes.lastUpdated", "tomatoes.fresh"}),
  #"Expanded tomatoes.viewer" = Table.ExpandRecordColumn(#"Expanded tomatoes", "tomatoes.viewer", {"rating", "numReviews", "meter"}, {"tomatoes.viewer.rating", "tomatoes.viewer.numReviews", "tomatoes.viewer.meter"}),
  #"Expanded tomatoes.critic" = Table.ExpandRecordColumn(#"Expanded tomatoes.viewer", "tomatoes.critic", {"rating", "numReviews", "meter"}, {"tomatoes.critic.rating", "tomatoes.critic.numReviews", "tomatoes.critic.meter"}),
  #"Replaced errors" = Table.ReplaceErrorValues(#"Expanded tomatoes.critic", {{"tomatoes.website", null},{"tomatoes.viewer.rating", null},{"tomatoes.viewer.numReviews", null},{"tomatoes.viewer.meter", null},{"tomatoes.dvd", null},{"tomatoes.critic.rating", null},{"tomatoes.critic.numReviews", null},{"tomatoes.critic.meter", null},{"tomatoes.lastUpdated", null},{"tomatoes.consensus", null},{"tomatoes.rotten", null},{"tomatoes.production", null},{"tomatoes.fresh", null}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Replaced errors", {{"imdb.id", type text}, {"imdb.votes", Int64.Type}, {"imdb.rating", type number}, {"tomatoes.website", type text}, {"tomatoes.dvd", type datetime}, {"tomatoes.consensus", type text}, {"tomatoes.production", type text}, {"tomatoes.viewer.rating", type number}, {"tomatoes.viewer.numReviews", Int64.Type}, {"tomatoes.viewer.meter", Int64.Type}, {"tomatoes.critic.rating", type number}, {"tomatoes.critic.numReviews", Int64.Type}, {"tomatoes.critic.meter", Int64.Type}, {"tomatoes.rotten", Int64.Type}, {"tomatoes.fresh", Int64.Type}, {"tomatoes.lastUpdated", type datetime}, {"tomatoes.boxOffice", type text}})

in
  #"Changed column type";
[BindToDefaultDestination = true]
shared genres = let
  Source = shows,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "genres"}),
  #"Removed errors" = Table.RemoveRowsWithErrors(#"Removed other columns", {"genres"}),
  #"Expanded genres" = Table.ExpandListColumn(#"Removed errors", "genres"),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded genres", {{"genres", type text}}),
  #"Renamed columns" = Table.RenameColumns(#"Changed column type", {{"genres", "genre"}})
in
  #"Renamed columns";
[BindToDefaultDestination = true]
shared actors = let
  Source = shows,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id","cast"}),
  #"Removed errors" = Table.RemoveRowsWithErrors(#"Removed other columns", {"cast"}),
  #"Expanded cast" = Table.ExpandListColumn(#"Removed errors", "cast"),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded cast", {{"cast", type text}}),
  #"Renamed columns" = Table.RenameColumns(#"Changed column type", {{"cast", "actor"}})
in
  #"Renamed columns";
[BindToDefaultDestination = true]
shared languages = let
  Source = shows,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "languages"}),
  #"Expanded languages" = Table.ExpandListColumn(#"Removed other columns", "languages"),
  #"Renamed columns" = Table.RenameColumns(#"Expanded languages", {{"languages", "language"}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns", {{"language", type text}})
in
  #"Changed column type";
[BindToDefaultDestination = true]
shared directors = let
  Source = shows,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id","directors"}),
  #"Expanded directors" = Table.ExpandListColumn(#"Removed other columns", "directors"),
  #"Renamed columns" = Table.RenameColumns(#"Expanded directors", {{"directors", "director"}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns", {{"director", type text}})
in
  #"Changed column type";
[BindToDefaultDestination = true]
shared countries = let
  Source = shows,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "countries"}),
  #"Expanded countries" = Table.ExpandListColumn(#"Removed other columns", "countries"),
  #"Renamed columns" = Table.RenameColumns(#"Expanded countries", {{"countries", "country"}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns", {{"country", type text}})
in
  #"Changed column type";
[BindToDefaultDestination = true]
shared writers = let
  Source = shows,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id","writers"}),
  #"Expanded writers" = Table.ExpandListColumn(#"Removed other columns", "writers"),
  #"Split column by delimiter" = Table.SplitColumn(Table.TransformColumnTypes(#"Expanded writers", {{"writers", type text}}), "writers", Splitter.SplitTextByDelimiter("("), {"writer", "role"}),
  #"Replaced value" = Table.ReplaceValue(#"Split column by delimiter", ")", "", Replacer.ReplaceText, {"role"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Replaced value", {{"writer", type text}, {"role", type text}}),
  #"Trimmed text" = Table.TransformColumns(#"Changed column type", {{"writer", each Text.Trim(_), type nullable text}, {"role", each Text.Trim(_), type nullable text}})
in
  #"Trimmed text";
shared theaters_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "0c648672-dabb-48fb-9451-fb7d3bd859a2"]}[Data],
  TableNavigation = Navigation_2{[Id = "theatres", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
