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

    global HttpRequest build(){
        return request;
    }

    global HttpResponse send(){
        return httpService.send(request);
    }
}
