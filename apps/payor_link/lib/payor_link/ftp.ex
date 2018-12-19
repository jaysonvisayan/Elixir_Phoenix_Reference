defmodule Innerpeace.PayorLink.FileTransferProtocol do
    @moduledoc false

    def start(host, username, password, port) do
        :inets.start
        host
        |> open_session(port) 
        |> sign_in(username, password)
    end

    def stop(session) do
        with :ok <- :inets.stop(:ftpc, session) do
            :ok
        else
            {:error, message} ->
                {:error, message}
        end
    end

    defp open_session(host, port) do
        if is_nil(port) do
            open_session_woutport(host)
        else
            open_session_wport(host, port)
        end
    end

    defp open_session_wport(host, port) do
        with {:ok, session} <- :inets.start(:ftpc, host: host, verbose: true, port: port) 
        do
            session
        else
            {:error, message} ->
                {:error, message}
        end
    end

    defp open_session_woutport(host) do
        with {:ok, session} <- :inets.start(:ftpc, host: host, verbose: true) 
        do
            session
        else
            {:error, message} ->
                {:error, message}
        end
    end

    defp sign_in(session, username, password) do
        with :ok <- :ftp.user(session, username, password) 
        do
            {:ok, session}
        else
            {:error, message} ->
                {:error, message}
        end
    end

    def set_remote_dir(session, path) do
        session
        |> get_remote_dir()
        |> check_remote_dir(session, path)
    end

    defp get_remote_dir(session) do
        with {:ok, remote_path} <- :ftp.pwd(session) 
        do
            remote_path
        else
            {:error, message} ->
                {:error, message}
        end
    end

    defp check_remote_dir(remote_path, session, path) do
        with :ok <- :ftp.cd(session, '#{remote_path}#{path}') 
        do
            {:ok, '#{remote_path}#{path}'}
        else
            {:error, message} ->
                {:error, message}
        end
    end

    def set_local_dir(session, path) do
        session
        |> get_local_dir()
        |> check_local_dir(session, path)
    end

    defp get_local_dir(session) do
        with {:ok, local_path} <- :ftp.lpwd(session) 
        do
            local_path
        else
            {:error, message} ->
                {:error, message}
        end
    end

    defp check_local_dir(local_path, session, path) do
        with :ok <- :ftp.lcd(session, '#{local_path}#{path}') 
        do
            {:ok, '#{local_path}#{path}'}
        else
            {:error, message} ->
                {:error, message}
        end
    end

    def transfer_file(session, file) do
        with :ok <- :ftp.append(session, file, file) do
            :ok
        else
            {:error, message} ->
                {:error, message}
        end
    end
end    