
require 'json'
require 'net/http'
require 'openssl'

class FlashArray
    def initialize(host, api_token)
        log("initializing FlashArray with host: #{host} and api_token: #{api_token}")
        @api_token = api_token
        @base_url = "https://#{host}/api/1.3"
        @session_cookie = nil
        log("#{@base_url}")
        start_session()
    end

    def log(str)
        Puppet.debug("#{self.class} #{str}")
    end

    def get(path)
        uri = URI.parse("#{@base_url}#{path}")
        request = Net::HTTP::Get.new(uri.path)
        return JSON.parse(send_request(request, uri).body)
    end

    def post(path, body, parse=true)
        log("#{self.class}.post #{path} #{body}")
        uri = URI.parse("#{@base_url}#{path}")
        request = Net::HTTP::Post.new(uri.path)
        request.body = JSON.generate(body)
        request.content_type = 'application/json'
        response = send_request(request, uri)
        if parse
            return JSON.parse(response.body)
        else
            return response
        end
    end

    def put(path, body)
        uri = URI.parse("#{@base_url}#{path}")
        request = Net::HTTP::Put.new(uri.path)
        request.body = JSON.generate(body)
        request.content_type = 'application/json'
        return JSON.parse(send_request(request, uri).body)
    end

    def delete(path, params=nil)
        uri = URI.parse("#{@base_url}#{path}")
        req_path = uri.path
        if params
            uri.query = URI.encode_www_form(params)
            req_path = "#{uri.path}?#{uri.query}"
        end
        request = Net::HTTP::Delete.new(req_path)
        return JSON.parse(send_request(request, uri).body)
    end

    def start_session()
        log("#{self.class}.start_session")
        response = post('/auth/session', {'api_token' => @api_token}, false)
        log("response = #{response}")
        @session_cookie = response['set-cookie'].split('; ')[0]
    end

    def send_request(req, uri, allow_retry=true)
        log("send_request: #{req.method} host=#{uri.host} path=#{uri.path} query=#{uri.query} allow_retry=#{allow_retry}")
        if @session_cookie
            req['Cookie'] = @session_cookie
        end
        Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
            res = https.request(req)
            log("#{res.code} #{res.message}")
            if res.code == 401 and allow_retry == true
                @session_cookie = nil
                start_session()
                res = send_request(req, false)
            end
            return res
        end
    end

    def list_volumes()
        log('list_volumes')
        return get('/volumes')
    end

    def create_volume(name, params={})
        log('create_volume')
        return post("/volume/#{name}", params)
    end

    def update_volume(name, params)
        log('update_volume')
        return put("/volume/#{name}", params)
    end

    def destroy_volume(name)
        log('destroy_volume')
        return delete("/volume/#{name}")
    end

    def eradicate_volume(name)
        log('eradicate_volume')
        params = {'eradicate' => true}
        return delete("/volume/#{name}", params)
    end

    def get_volume(name)
        log('get_volume')
        return get("/volume/#{name}")
    end

    def create_host(name, iqnlist=nil, wwnlist=nil)
        log('create_host')
        body = {}
        if iqnlist != nil
            body['iqnlist'] = iqnlist
        end
        if wwnlist
            body['wwnlist'] = wwnlist
        end

        return post("/host/#{name}", body)
    end

    def delete_host(name)
        log('delete_host')
        return delete("/host/#{name}")
    end

    def update_host(name, params)
        log('update_host')
        return put("/host/#{name}", params)
    end

    def get_host(name)
        log('get_host')
        return get("/host/#{name}")
    end

    def connect_volume(volume, host)
        log('connect_volume')
        return post("/host/#{host}/volume/#{volume}")
    end

    def disconnect_volume(volume, host)
        log('disconnect_volume')
        return delete("/host/#{host}/volume/#{volume}")
    end

    def list_host_connections(host)
        log('list_connections')
        return get("/host/#{host}/volume")
    end

    def list_volume_connections(volume)
        log('list_connections')
        return get("/volume/#{volume}/host")
    end
end