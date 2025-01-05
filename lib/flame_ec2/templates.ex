defmodule FlameEC2.Templates do
  @moduledoc false

  require EEx

  @templates_path Path.absname("./templates", __DIR__)

  @type systemd_assign() ::
          {:app, atom() | String.t()} | {:custom_start_command, String.t()} | {:custom_stop_command, String.t()}
  @spec systemd_service([systemd_assign()]) :: String.t()
  def systemd_service(assigns) do
    systemd_service_template(assigns)
  end

  @type env_assign() :: {:vars, %{String.t() => String.t() | atom() | number()}}
  @spec env([env_assign()]) :: String.t()
  def env(assigns) do
    env_template(assigns)
  end

  @type start_script_assign() ::
          {:systemd_service, String.t()}
          | {:env, String.t()}
          | {:app, String.t()}
          | {:aws_region, String.t()}
          | {:s3_bundle_url, String.t()}
          | {:s3_bundle_compressed?, boolean()}
  @spec start_script([start_script_assign()]) :: String.t()
  def start_script(assigns) do
    start_script_template(assigns)
  end

  EEx.function_from_file(:defp, :systemd_service_template, Path.join(@templates_path, "systemd.service.eex"), [:assigns])
  EEx.function_from_file(:defp, :env_template, Path.join(@templates_path, "env.eex"), [:assigns])
  EEx.function_from_file(:defp, :start_script_template, Path.join(@templates_path, "start.sh.eex"), [:assigns])
end
