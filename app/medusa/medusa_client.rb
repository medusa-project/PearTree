class MedusaClient

  @@client = nil

  ##
  # @return [HTTPClient] With auth credentials already set.
  #
  def self.http_client
    unless @@client
      @@client = HTTPClient.new do
        config = Configuration.instance
        self.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        self.force_basic_auth = true
        self.receive_timeout = 10000
        uri = URI.parse(config.medusa_url)
        domain = uri.scheme + '://' + uri.host
        user = config.medusa_user
        secret = config.medusa_secret
        self.set_auth(domain, user, secret)
      end
    end
    @@client
  end

  ##
  # @param uuid [String]
  # @return [Class]
  #
  def class_of_uuid(uuid)
    url = Configuration.instance.medusa_url.chomp('/') + '/uuids/' +
        uuid.to_s.strip + '.json'
    begin
    response = get(url, follow_redirect: false)
    location = response.header['location'].first
    if location.include?('/bit_level_file_groups/')
      return MedusaFileGroup
    elsif location.include?('/cfs_directories/')
      return MedusaCfsDirectory
    elsif location.include?('/cfs_files/')
      return MedusaCfsFile
    end
    rescue HTTPClient::BadResponseError
      # no-op
    end
    nil
  end

  def get(url, *args)
    args = merge_args(args)
    self.class.http_client.get(url, args)
  end

  def head(url, *args)
    args = merge_args(args)
    self.class.http_client.head(url, args)
  end

  private

  def merge_args(args)
    extra_args = { follow_redirect: true }
    if args[0].kind_of?(Hash)
      args[0] = extra_args.merge(args[0])
    else
      return extra_args
    end
    args
  end

end