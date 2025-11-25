global virtual class HttpResponseBuilder {
    protected HttpResponse response;

    global HttpResponseBuilder() {
        this.response = new HttpResponse();
    }

    global static HttpResponseBuilder init(){
        return new HttpResponseBuilder();
    }

    global HttpResponseBuilder status(String value){
        this.response.setStatus(value);
        return this;
    }

    global HttpResponseBuilder statusCode(Integer value){
        this.response.setStatusCode(value);
        return this;
    }

    global HttpResponseBuilder header(String key, String value){
        this.response.setHeader(key, value);
        return this;
    }

    global HttpResponseBuilder body(String value){
        this.response.setBody(value);
        return this;
    }

    global HttpResponseBuilder body(Blob value){
        this.response.setBodyAsBlob(value);
        return this;
    }

    global HttpResponse build(){
        return response;
    }
}
