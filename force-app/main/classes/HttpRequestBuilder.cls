global virtual class HttpRequestBuilder {
    private static Http httpService = new Http();
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
        this.request.setBody(value);
        return this;
    }

    global HttpRequestBuilder body(Dom.Document value){
        this.request.setBodyDocument(value);
        return this;
    }

    global HttpRequestBuilder body(Blob value){
        this.request.setBodyAsBlob(value);
        return this;
    }

    global MultipartBodyBuilder multipartBody(){
        return new MultipartBodyBuilder(this);
    }

    global HttpRequest build(){
        return request;
    }

    global HttpResponse send(){
        return httpService.send(request);
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
            return addField(name, value, null);
        }

        global MultipartBodyBuilder addField(String name, String value, String contentType){
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
            part += 'Content-Disposition: form-data; name="' + name + '"; filename="' + filename + '"';
            part += '\r\nContent-Type: ' + contentType + '\r\n\r\n';

            body += calculatePart(part, value);

            return this;
        }

        global HttpRequestBuilder setMultipartBody(){
            String finalBoundary = getBoundary(true);


            System.debug(body + finalBoundary);
            if(encoded){
                //If encoded, the body is in base64 and NEVER ends with '=', allowing me to append directly.
                return reqBuilder.body(EncodingUtil.base64Decode(body + encodeString(finalBoundary)));
            }else{
                return reqBuilder.body(body + finalBoundary);
            }
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
            boundaryPrefix = '\r\n';

            if(encoded){
                String encodedPart;

                do{
                    encodedPart = encodeString(part);
                    if(encodedPart.endsWith('=')){
                        part = part.removeEnd('\r\n\r\n') + ' \r\n\r\n';
                    }
                }while(encodedPart.endsWith('='));

                part = encodedPart;

                String encodedValue = EncodingUtil.base64Encode(value);
                if(encodedValue.endsWith('==')){
                    encodedValue = encodedValue.substringBeforeLast('==') + '0K';
                    boundaryPrefix = '';
                }else if(encodedValue.endsWith('=')){
                    encodedValue = encodedValue.substringBeforeLast('=') + 'N';
                    boundaryPrefix = '\n';
                }

                part += encodedValue;

            }else{
                part += value.toString();
            }

            return part;
        }

        private String encodeString(String s){
            return EncodingUtil.base64Encode(Blob.valueOf(s));
        }
    }
}
