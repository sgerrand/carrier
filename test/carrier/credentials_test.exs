defmodule Carrier.CredentialsTest do

  alias Carrier.Credentials

  use Carrier.Test.Hygiene
  use Carrier.Test.IO

  defp perturb(v) when is_binary(v) do
    <<value::integer>> = v
    value = if value < 255 do
      value + 1
    else
      value - 1
    end
    <<value>>
  end

  test "create new credentials dir w/correct permissions" do
    credentials_root = temp_dir!
    assert Credentials.validate_files!(credentials_root)
  end

  test "fail when credentials dir has wrong mode" do
    credentials_root = temp_dir!
    File.mkdir_p!(credentials_root)
    File.chmod!(credentials_root, 0o777)
    error = assert_raise(Carrier.SecurityError, fn -> Credentials.validate_files!(credentials_root) end)
    assert error.message == "Path #{credentials_root} should have mode 40700 but has 40777 instead"
  end

  test "fail when key files are missing" do
    credentials_root = temp_dir!
    File.mkdir_p!(credentials_root)
    File.chmod!(credentials_root, 0o700)
    error = assert_raise(File.Error, fn -> Credentials.validate_files!(credentials_root) end)
    assert error.reason == :enoent
  end

  test "fail when keys are corrupted" do
    credentials_root = temp_dir!
    assert Credentials.validate_files!(credentials_root)
    priv_key_path = Path.join(credentials_root, "carrier_priv.key")
    # Perturb hash to trigger corrupt key failure
    <<hash::binary-size(63), bad::binary-size(1), key::binary>> = File.read!(priv_key_path)
    bad = perturb(bad)
    File.write!(priv_key_path, <<hash::binary, bad::binary, key::binary>>, [:write])
    error = assert_raise(Carrier.SecurityError, fn -> Credentials.validate_files!(credentials_root) end)
    assert error.message == "Credential file #{priv_key_path} is corrupted. Please generate a new credential set."
  end

  test "fail when keys are undersized" do
    credentials_root = temp_dir!
    assert Credentials.validate_files!(credentials_root)
    priv_key_path = Path.join(credentials_root, "carrier_priv.key")
    File.write!(priv_key_path, "A very bad key", [:write])
    error = assert_raise(Carrier.SecurityError, fn -> Credentials.validate_files!(credentials_root) end)
    assert error.message == "Credential file #{priv_key_path} is corrupted. Please generate a new credential set."
  end

  test "fail when keys have wrong mode" do
    credentials_root = temp_dir!
    assert Credentials.validate_files!(credentials_root)
    pub_key_path = Path.join(credentials_root, "carrier_pub.key")
    File.chmod!(pub_key_path, 0o644)
    error = assert_raise(Carrier.SecurityError, fn -> Credentials.validate_files!(credentials_root) end)
    assert error.message == "Path #{pub_key_path} should have mode 100600 but has 100644 instead"
  end

  test "saving public credentials" do
    credentials_root = temp_dir!
    File.mkdir_p!(credentials_root)
    credentials = Credentials.generate()
    Credentials.write_public_credentials!(credentials_root, credentials)
    :ok
  end

  test "reading public credentials" do
    credentials_root = temp_dir!
    Credentials.validate_files!(credentials_root)
    credentials = Credentials.generate()
    Credentials.write_public_credentials!(credentials_root, credentials)
    [{name, creds}] = Credentials.read_all_credentials!(credentials_root)
    assert name == credentials.id
    assert creds.public == credentials.public
    assert creds.id == credentials.id
    assert creds.private == nil
  end

end