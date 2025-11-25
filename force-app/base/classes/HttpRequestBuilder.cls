global virtual class HttpRequestBuilder {
    private static Http httpService = new Http();
    private static RequestLoggingInterface logger;
    private HttpRequest request;

    private String namedCredential;
    private String endpoint;

    private HttpRequestBuilder(String method) {
        this.request = new HttpRequest();
        this.request.setMethod(method);
    }

    global static HttpRequestBuilder get(){
        return new HttpRequestBuilder('GET');
    }

    global static HttpRequestBuilder post(){
        return new HttpRequestBuilder('POST');
    }

    global static HttpRequestBuilder patch(){
        return new HttpRequestBuilder('PATCH');
    }

    global static HttpRequestBuilder put(){
        return new HttpRequestBuilder('PUT');
    }

    global static HttpRequestBuilder del(){
        return new HttpRequestBuilder('DELETE');
    }

    global static HttpRequestBuilder init(String method){
        return new HttpRequestBuilder(method);
    }

    global static void enableLogging(RequestLoggingInterface logger){
        HttpRequestBuilder.logger = logger;
    }

    global HttpRequestBuilder namedCredential(String namedCredential){
        this.namedCredential = namedCredential;
        buildEndpoint();
        return this;
    }

    global HttpRequestBuilder endpoint(String value){
        this.endpoint = value;
        buildEndpoint();
        return this;
    }

    private void buildEndpoint(){
        String fqdn = '';
        if(namedCredential != null){
            fqdn += 'callout:' + namedCredential;
        }
        if(endpoint != null){
            fqdn += endpoint;
        }
        this.request.setEndpoint(fqdn);
    }

    global HttpRequestBuilder timeout(Integer value){
        this.request.setTimeout(value);
        return this;
    }

    global HttpRequestBuilder header(String key, String value){
        this.request.setHeader(key, value);
        return this;
    }

    global HttpRequestBuilder clientCertificate(String value){
        this.request.setClientCertificateName(value);
        return this;
    }

    global HttpRequestBuilder compressed(Boolean value){
        this.request.setCompressed(value);
        return this;
    }

    global HttpRequestBuilder body(String value){
        if(value != null){
            this.request.setBody(value);
        }
        return this;
    }

    global HttpRequestBuilder body(Dom.Document value){
        if(value != null){
            this.request.setBodyDocument(value);
        }
        return this;
    }

    global HttpRequestBuilder body(Blob value){
        if(value != null){
            this.request.setBodyAsBlob(value);
        }
        return this;
    }

    global MultipartBodyBuilder multipartBody(){
        return new MultipartBodyBuilder(this);
    }

    global HttpRequest build(){
        return request;
    }

    global HttpResponse send(){
        HttpResponse response = httpService.send(request);
        if(logger != null){
            logger.log(request, response);
        }
        return response;
    }

    global class MultipartBodyBuilder{
        private HttpRequestBuilder reqBuilder;
        private String boundary = '-----x' + DateTime.now().getTime() + 'x-----';
        private String body = '';
        private Boolean encoded = false;
        private String boundaryPrefix = '';

        private MultipartBodyBuilder(HttpRequestBuilder reqBuilder){
            this.reqBuilder = reqBuilder;
            reqBuilder.header('Content-Type', 'multipart/form-data; boundary=' + boundary);
        }

        global MultipartBodyBuilder addField(String name, String value){
            return addField(name, null, value);
        }

        global MultipartBodyBuilder addField(String name, String contentType, String value){
            String part = getBoundary();
            part += 'Content-Disposition: form-data; name="' + name + '"';
            if(contentType != null){
                part += '\r\nContent-Type: ' + contentType;
            }
            part += '\r\n\r\n';

            body += calculatePart(part, Blob.valueOf(value));

            return this;
        }

        global MultipartBodyBuilder addFile(String name, String filename, Blob value){
            return addFile(name, filename, 'application/octet-stream', value);
        }

        global MultipartBodyBuilder addFile(String name, String filename, String contentType, Blob value){
            String part = getBoundary();

            //When the first file is added, we switch to a base64 encoded format.
            //To make the switch, we will include the entire body up to now in the first encoding.
            if(encoded == false){
                encoded = true;
                part = body + part;
                body = '';
            }

            part += 'Content-Disposition: form-data; name="' + name + '"; filename="' + filename + '"';
            part += '\r\nContent-Type: ' + contentType + '\r\n\r\n';

            body += calculatePart(part, value);

            return this;
        }

        global HttpRequestBuilder setMultipartBody(){
            String finalBoundary = getBoundary(true);

            if(encoded){
                //If encoded, the body is in base64 and NEVER ends with '=', allowing me to append directly.
                reqBuilder.body(EncodingUtil.base64Decode(body + encodeString(finalBoundary)));
            }else{
                reqBuilder.body(body + finalBoundary);
            }

            return reqBuilder;
        }

        private String getBoundary(){
            return getBoundary(false);
        }

        private String getBoundary(Boolean isFinal){
            String ending = isFinal ? '--' : '\r\n';
            String boundary = boundaryPrefix + '--' + boundary + ending;
            boundaryPrefix = '';
            return boundary;
        }

        private String calculatePart(String part, Blob value){
            //The default boundary prefix is \r\n, unless we need to include one of those characters
            //in the encoding of the prior part to ensure an justified encoding (no trailing =).
            boundaryPrefix = '\r\n';

            if(encoded){
                String encodedPart;

                do{
                    encodedPart = encodeString(part);
                    //If a trailing =, pad the part headers with a space character until it does not.
                    if(encodedPart.endsWith('=')){
                        part = part.removeEnd('\r\n\r\n') + ' \r\n\r\n';
                    }
                }while(encodedPart.endsWith('='));

                part = encodedPart;

                //Encode the value as base64. If trailing = exists, make the appropriate replacement.
                String encodedValue = EncodingUtil.base64Encode(value);
                if(encodedValue.endsWith('==')){
                    encodedValue = encodedValue.substringBeforeLast('==') + '0K'; //Equivalent to \r\n
                    boundaryPrefix = ''; //Leave nothing to be prefixed on the next boundary
                }else if(encodedValue.endsWith('=')){
                    encodedValue = encodedValue.substringBeforeLast('=') + 'N'; //Equivalent to \r
                    boundaryPrefix = '\n'; //Leaves \n to be prefixed on the next boundary
                }

                part += encodedValue;

            }else{
                //Its not encoded, so just append the value
                part += value.toString();
            }

            return part;
        }

        private String encodeString(String s){
            return EncodingUtil.base64Encode(Blob.valueOf(s));
        }
    }
}
