[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "companies_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared companies = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "companies", ItemKind = "Table"]}[Data],
  #"Parse json" = Table.TransformColumns(#"Navigation 2", {{"image", each Json.Document(_), type nullable any},{"products", each Json.Document(_), type nullable any},{"relationships", each Json.Document(_), type nullable any},{"competitions", each Json.Document(_), type nullable any},{"providerships", each Json.Document(_), type nullable any},{"funding_rounds", each Json.Document(_), type nullable any},{"investments", each Json.Document(_), type nullable any},{"acquisition", each Json.Document(_), type nullable any},{"acquisitions", each Json.Document(_), type nullable any},{"offices", each Json.Document(_), type nullable any},{"milestones", each Json.Document(_), type nullable any},{"video_embeds", each Json.Document(_), type nullable any},{"screenshots", each Json.Document(_), type nullable any},{"external_links", each Json.Document(_), type nullable any},{"partners", each Json.Document(_), type nullable any},{"ipo", each Json.Document(_), type nullable any}}),
  #"Replaced errors" = Table.ReplaceErrorValues(#"Parse json", {{"image", null},{"products", null},{"relationships", null},{"competitions", null},{"providerships", null},{"funding_rounds", null},{"investments", null},{"acquisition", null},{"acquisitions", null},{"offices", null},{"milestones", null},{"video_embeds", null},{"screenshots", null},{"external_links", null},{"partners", null},{"ipo", null}}),
  #"Expanded image" = Table.ExpandRecordColumn(#"Replaced errors", "image", {"available_sizes", "attribution"}, {"image.available_sizes", "image.attribution"}),
  #"Expanded ipo" = Table.ExpandRecordColumn(#"Expanded image", "ipo", {"valuation_amount", "valuation_currency_code", "pub_year", "pub_month", "pub_day", "stock_symbol"}, {"ipo.valuation_amount", "ipo.valuation_currency_code", "ipo.pub_year", "ipo.pub_month", "ipo.pub_day", "ipo.stock_symbol"}),
  #"Parse datetime" = Table.TransformColumns(#"Expanded ipo", {{"created_at", each DateTime.FromText(_, [Format=if Text.Contains(_," ") then "ddd MMM dd HH:mm:ss UTC yyyy" else "yyyy-MM-dd'T'HH:mm:ss"]), type nullable text},{"updated_at", each DateTime.FromText(_, [Format=if Text.Contains(_," ") then "ddd MMM dd HH:mm:ss UTC yyyy" else "yyyy-MM-dd'T'HH:mm:ss"]), type nullable text}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Parse datetime", {{"deadpooled_month", Int64.Type}, {"ipo.valuation_amount", Int64.Type}, {"ipo.valuation_currency_code", type text}, {"ipo.pub_year", Int64.Type}, {"ipo.pub_month", Int64.Type}, {"ipo.pub_day", Int64.Type}, {"ipo.stock_symbol", type text}, {"founded_year", Int64.Type}, {"founded_month", Int64.Type}, {"number_of_employees", Int64.Type}, {"founded_day", Int64.Type}, {"deadpooled_year", Int64.Type}, {"created_at", type datetime}, {"updated_at", type datetime}, {"deadpooled_day", Int64.Type}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "products_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared products = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"products", "_id"}),
  #"Expanded products" = Table.ExpandListColumn(#"Removed other columns", "products"),
  #"Expanded product" = Table.ExpandRecordColumn(#"Expanded products", "products", {"name", "permalink"}, {"name", "permalink"}),
  #"Filtered rows" = Table.SelectRows(#"Expanded product", each [permalink] <> null and [permalink] <> ""),
  #"Changed column type" = Table.TransformColumnTypes(#"Filtered rows", {{"name", type text}, {"permalink", type text}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "relationships_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared relationships = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "relationships"}),
  #"Expanded relationships" = Table.ExpandListColumn(#"Removed other columns", "relationships"),
  #"Expanded relationship" = Table.ExpandRecordColumn(#"Expanded relationships", "relationships", {"is_past", "title", "person"}, {"is_past", "title", "person"}),
  #"Expanded person" = Table.ExpandRecordColumn(#"Expanded relationship", "person", {"first_name", "last_name", "permalink"}, {"first_name", "last_name", "permalink"}),
  #"Filtered rows" = Table.SelectRows(#"Expanded person", each [permalink] <> null and [permalink] <> ""),
  #"Added name" = Table.AddColumn(#"Filtered rows", "name", each [first_name] & " " & [last_name]),
  #"Removed columns" = Table.RemoveColumns(#"Added name", {"first_name", "last_name"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed columns", {{"name", type text}, {"is_past", type logical}, {"title", type text}, {"permalink", type text}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "images_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared images = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "image.available_sizes", "image.attribution"}),
  #"Expanded available_sizes" = Table.ExpandListColumn(#"Removed other columns", "image.available_sizes"),
  #"Added custom" = Table.AddColumn(#"Expanded available_sizes", "image.url", each List.Last([image.available_sizes])),
  #"Removed errors" = Table.RemoveRowsWithErrors(#"Added custom", {"image.url"}),
  #"Removed columns" = Table.RemoveColumns(#"Removed errors", {"image.available_sizes", "image.attribution"}),
  #"Appended query" = Table.Combine({#"Removed columns", screenshots}),
  #"Changed column type" = Table.TransformColumnTypes(#"Appended query", {{"image.url", type text}}),
  #"Removed duplicates" = Table.Distinct(#"Changed column type", {"image.url"})
in
  #"Removed duplicates";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "competitions_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared competitions = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "competitions"}),
  #"Expanded competitions" = Table.ExpandListColumn(#"Removed other columns", "competitions"),
  #"Expanded competition" = Table.ExpandRecordColumn(#"Expanded competitions", "competitions", {"competitor"}, {"competitor"}),
  #"Expanded competitor" = Table.ExpandRecordColumn(#"Expanded competition", "competitor", {"name", "permalink"}, {"name", "permalink"}),
  #"Filtered rows" = Table.SelectRows(#"Expanded competitor", each [permalink] <> null and [permalink] <> ""),
  #"Changed column type" = Table.TransformColumnTypes(#"Filtered rows", {{"permalink", type text}, {"name", type text}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "providerships_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared providerships = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "providerships"}),
  #"Expanded providerships" = Table.ExpandListColumn(#"Removed other columns", "providerships"),
  #"Expanded providership" = Table.ExpandRecordColumn(#"Expanded providerships", "providerships", {"title", "is_past", "provider"}, {"title", "is_past", "provider"}),
  #"Expanded provider" = Table.ExpandRecordColumn(#"Expanded providership", "provider", {"name", "permalink"}, {"name", "permalink"}),
  #"Filtered rows" = Table.SelectRows(#"Expanded provider", each [permalink] <> null and [permalink] <> ""),
  #"Changed column type" = Table.TransformColumnTypes(#"Filtered rows", {{"permalink", type text}, {"name", type text}, {"is_past", type logical}, {"title", type text}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "fundings_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared fundings = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "funding_rounds"}),
  #"Expanded funding_rounds" = Table.ExpandListColumn(#"Removed other columns", "funding_rounds"),
  #"Expanded funding_round" = Table.ExpandRecordColumn(#"Expanded funding_rounds", "funding_rounds", {"id", "round_code", "source_url", "source_description", "raised_amount", "raised_currency_code", "funded_year", "funded_month", "funded_day", "investments"}, {"id", "round_code", "source_url", "source_description", "raised_amount", "raised_currency_code", "funded_year", "funded_month", "funded_day", "investments"}),
  #"Filtered rows" = Table.SelectRows(#"Expanded funding_round", each [id] <> null and [id] <> ""),
  #"Added funding_id" = Table.TransformColumnTypes(Table.AddColumn(#"Filtered rows", "funding_id", each [_id] & Text.From([funded_year]) & Text.From([funded_month]??99) & Text.From([funded_day]??99)), {{"funding_id", type text}}),
  #"Appended query" = Table.Combine({#"Added funding_id", funding_investments}),
  #"Changed column type" = Table.TransformColumnTypes(#"Appended query", {{"round_code", type text}, {"id", type text}, {"source_url", type text}, {"source_description", type text}, {"raised_amount", Int64.Type}, {"raised_currency_code", type text}, {"funded_year", Int64.Type}, {"funded_month", Int64.Type}, {"funded_day", Int64.Type}}),
  #"Removed duplicates" = Table.Distinct(#"Changed column type", {"funding_id"})
in
  #"Removed duplicates";
shared funding_investments = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "investments"}),
  #"Expanded investments" = Table.ExpandListColumn(#"Removed other columns", "investments"),
  #"Filtered rows" = Table.SelectRows(#"Expanded investments", each [investments] <> null and [investments] <> ""),
  #"Expanded investment" = Table.ExpandRecordColumn(#"Filtered rows", "investments", {"funding_round"}, {"funding_round"}),
  #"Expanded funding_round" = Table.ExpandRecordColumn(#"Expanded investment", "funding_round", {"round_code", "source_url", "source_description", "raised_amount", "raised_currency_code", "funded_year", "funded_month", "funded_day", "company"}, {"round_code", "source_url", "source_description", "raised_amount", "raised_currency_code", "funded_year", "funded_month", "funded_day", "company"}),
  #"Added funding_id" = Table.TransformColumnTypes(Table.AddColumn(#"Expanded funding_round", "funding_id", each [_id]&Text.From([funded_year])&Text.From([funded_month]??99)&Text.From([funded_day]??99)), {{"funding_id", type text}}),
  #"Expanded company" = Table.ExpandRecordColumn(#"Added funding_id", "company", {"name", "permalink"}, {"name", "permalink"}),
  #"Added investments" = Table.AddColumn(#"Expanded company", "investments", each Json.Document("[{""company"":{""name"":"""&[name]&""",""permalink"":"""&[permalink]&"""}}]")),
  #"Removed columns" = Table.RemoveColumns(#"Added investments", {"name", "permalink"})
in
  #"Removed columns";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "investments_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared investments = let
  Source = fundings,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "funding_id", "investments"}),
  #"Expanded investments" = Table.ExpandListColumn(#"Removed other columns", "investments"),
  #"Expanded investment" = Table.ExpandRecordColumn(#"Expanded investments", "investments", {"company", "financial_org", "person"}, {"company", "financial_org", "person"}),
  #"Expanded financial_org" = Table.ExpandRecordColumn(#"Expanded investment", "financial_org", {"name", "permalink"}, {"org.name", "org.permalink"}),
  #"Expanded company" = Table.ExpandRecordColumn(#"Expanded financial_org", "company", {"name", "permalink"}, {"company.name", "company.permalink"}),
  #"Expanded person" = Table.ExpandRecordColumn(#"Expanded company", "person", {"first_name", "last_name", "permalink"}, {"first_name",  "last_name", "person.permalink"}),
  #"Added permalink" = Table.TransformColumnTypes(Table.AddColumn(#"Expanded person", "permalink", each [person.permalink]??([org.permalink]??[company.permalink])), {{"permalink", type text}}),
  #"Filtered rows" = Table.SelectRows(#"Added permalink", each [permalink] <> null and [permalink] <> ""),
  #"Added name" = Table.TransformColumnTypes(Table.AddColumn(#"Filtered rows", "name", each [org.name]??([company.name]??[first_name] & " " & [last_name])), {{"name", type text}}),
  #"Removed others" = Table.SelectColumns(#"Added name", {"_id","funding_id", "permalink", "name"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed others", {{"name", type text}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "acquisitions_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared acquisitions = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "acquisition", "acquisitions"}),
  #"Expanded acquisitions" = Table.ExpandListColumn(#"Removed other columns", "acquisitions"),
  #"Added custom" = Table.AddColumn(#"Expanded acquisitions", "acquisition_", each if [acquisitions] <> null then [acquisitions] else [acquisition]),
  #"Removed columns" = Table.RemoveColumns(#"Added custom", {"acquisition", "acquisitions"}),
  #"Expanded record" = Table.ExpandRecordColumn(#"Removed columns", "acquisition_", {"price_amount", "price_currency_code", "term_code", "source_url", "source_description", "acquired_year", "acquired_month", "acquired_day", "acquiring_company", "company"}, {"price_amount", "price_currency_code", "term_code", "source_url", "source_description", "acquired_year", "acquired_month", "acquired_day", "acquiring_company", "company"}),
  #"Filtered rows" = Table.SelectRows(#"Expanded record", each [acquired_year] <> null and [acquired_year] <> ""),
  #"Expanded acquiring_company" = Table.ExpandRecordColumn(#"Filtered rows", "acquiring_company", {"name"}, {"acquiring_company"}),
  #"Expanded company" = Table.ExpandRecordColumn(#"Expanded acquiring_company", "company", {"name"}, {"acquired_company"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded company", {{"price_amount", Int64.Type}, {"price_currency_code", type text}, {"term_code", type text}, {"source_url", type text}, {"source_description", type text}, {"acquired_year", Int64.Type}, {"acquired_month", Int64.Type}, {"acquired_day", Int64.Type}, {"acquiring_company", type text}, {"acquired_company", type text}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "offices_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared offices = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "offices"}),
  #"Expanded offices" = Table.ExpandListColumn(#"Removed other columns", "offices"),
  #"Expanded office" = Table.ExpandRecordColumn(#"Expanded offices", "offices", {"description", "address1", "address2", "zip_code", "city", "state_code", "country_code", "latitude", "longitude"}, {"description", "address1", "address2", "zip_code", "city", "state_code", "country_code", "latitude", "longitude"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded office", {{"description", type text}, {"address1", type text}, {"address2", type text}, {"zip_code", type text}, {"city", type text}, {"state_code", type text}, {"country_code", type text}, {"latitude", type number}, {"longitude", type number}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "milestones_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared milestones = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "milestones"}),
  #"Expanded milestones" = Table.ExpandListColumn(#"Removed other columns", "milestones"),
  #"Expanded milestone" = Table.ExpandRecordColumn(#"Expanded milestones", "milestones", {"id", "description", "stoned_year", "stoned_month", "stoned_day", "source_url", "source_text", "source_description", "stoneable_type", "stoned_value", "stoned_value_type", "stoned_acquirer", "stoneable"}, {"id", "description", "stoned_year", "stoned_month", "stoned_day", "source_url", "source_text", "source_description", "stoneable_type", "stoned_value", "stoned_value_type", "stoned_acquirer", "stoneable"}),
  #"Filtered rows" = Table.SelectRows(#"Expanded milestone", each [id] <> null and [id] <> ""),
  #"Expanded stoneable" = Table.ExpandRecordColumn(#"Filtered rows", "stoneable", {"name", "permalink"}, {"name", "permalink"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded stoneable", {{"id", Int64.Type}, {"description", type text}, {"stoned_year", Int64.Type}, {"stoned_month", Int64.Type}, {"stoned_day", Int64.Type}, {"source_url", type text}, {"source_text", type text}, {"source_description", type text}, {"stoneable_type", type text}, {"name", type text}, {"permalink", type text}, {"stoned_acquirer", type text}, {"stoned_value_type", type text}, {"stoned_value", type text}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "partners_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared partners = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "partners"}),
  #"Expanded partners" = Table.ExpandListColumn(#"Removed other columns", "partners"),
  #"Filtered rows" = Table.SelectRows(#"Expanded partners", each [partners] <> null and [partners] <> ""),
  #"Expanded partner" = Table.ExpandRecordColumn(#"Filtered rows", "partners", {"partner_name", "homepage_url", "link_1_url", "link_2_url", "link_3_url", "link_1_name", "link_2_name", "link_3_name"}, {"partner_name", "homepage_url", "link_1_url", "link_2_url", "link_3_url", "link_1_name", "link_2_name", "link_3_name"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded partner", {{"partner_name", type text}, {"homepage_url", type text}, {"link_1_url", type text}, {"link_2_url", type text}, {"link_3_url", type text}, {"link_1_name", type text}, {"link_2_name", type text}, {"link_3_name", type text}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "videos_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared videos = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "video_embeds"}),
  #"Expanded video_embeds" = Table.ExpandListColumn(#"Removed other columns", "video_embeds"),
  #"Filtered rows" = Table.SelectRows(#"Expanded video_embeds", each [video_embeds] <> null and [video_embeds] <> ""),
  #"Expanded video_embed" = Table.ExpandRecordColumn(#"Filtered rows", "video_embeds", {"embed_code", "description"}, {"embed_code", "description"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded video_embed", {{"embed_code", type text}, {"description", type text}})
in
  #"Changed column type";
shared screenshots = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "screenshots"}),
  #"Expanded screenshots" = Table.ExpandListColumn(#"Removed other columns", "screenshots"),
  #"Expanded screenshot" = Table.ExpandRecordColumn(#"Expanded screenshots", "screenshots", {"available_sizes", "attribution"}, {"available_sizes", "attribution"}),
  #"Expanded available_sizes" = Table.ExpandListColumn(#"Expanded screenshot", "available_sizes"),
  #"Added custom" = Table.AddColumn(#"Expanded available_sizes", "image.url", each List.Last([available_sizes])),
  #"Removed errors" = Table.RemoveRowsWithErrors(#"Added custom", {"image.url"}),
  #"Removed columns" = Table.RemoveColumns(#"Removed errors", {"attribution", "available_sizes"})
in
  #"Removed columns";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "links_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared links = let
  Source = companies,
  #"Removed other columns" = Table.SelectColumns(Source, {"_id", "external_links"}),
  #"Expanded external_links" = Table.ExpandListColumn(#"Removed other columns", "external_links"),
  #"Expanded external_link" = Table.ExpandRecordColumn(#"Expanded external_links", "external_links", {"external_url", "title"}, {"external_url", "title"}),
  #"Filtered rows" = Table.SelectRows(#"Expanded external_link", each [external_url] <> null and [external_url] <> ""),
  #"Changed column type" = Table.TransformColumnTypes(#"Filtered rows", {{"external_url", type text}, {"title", type text}}),
  #"Removed duplicates" = Table.Distinct(#"Changed column type", {"external_url"})
in
  #"Removed duplicates";
shared products_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "products", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared relationships_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "relationships", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared images_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "images", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared competitions_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "competitions", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared providerships_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "providerships", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared fundings_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "fundings", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared investments_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "investments", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared acquisitions_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "acquisitions", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared offices_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "offices", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared milestones_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "milestones", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared partners_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "partners", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared videos_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "videos", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared links_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "links", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared companies_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = null, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "2e558e5c-dad3-4673-8242-c21e57e63da5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "85ea02a7-d1dc-464c-a28a-b88a7362a4f1"]}[Data],
  TableNavigation = Navigation_2{[Id = "companies_cleansed", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
