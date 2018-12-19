{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Innerpeace.Db.Repo, :manual)

Code.load_file("../db/test/support/factories.ex")
Code.load_file("../db/test/support/schema_case.ex")
