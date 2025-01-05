defmodule FlameEC2.Templates do
  @moduledoc false

  require EEx

  @templates_path Path.absname("./templates", __DIR__)

  EEx.function_from_file(:def, :systemd_service, Path.join(@templates_path, "systemd.service.eex"), [:assigns])
  EEx.function_from_file(:def, :env, Path.join(@templates_path, "env.eex"), [:assigns])
  EEx.function_from_file(:def, :start_script, Path.join(@templates_path, "start.sh.eex"), [:assigns])
end
