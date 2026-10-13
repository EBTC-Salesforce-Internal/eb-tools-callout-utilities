@isTest
public with sharing class CalloutLoggingAdapterTest {
    @isTest
    public static void publishesCallout(){
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('https://example.com/resource');
        request.setBody('{"request":true}');

        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody('{"response":true}');

        Test.startTest();
        new CalloutLoggingAdapter().log(request, response);
        Test.stopTest();
    }

    @isTest
    public static void buildsCalloutWithRedactedFields(){
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('https://example.com/resource?access_token=secret&mode=full');
        request.setBody('request token-123');

        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setHeader('X-Secret', 'response secret');
        response.setHeader('Content-Type', 'application/json');
        response.setBody('response token-456');

        CalloutLogRedaction redaction = new CalloutLogRedaction()
            .header('x-secret')
            .urlParameter('access_token')
            .bodyPattern('token-[0-9]+');
        LogHelper helper = new CalloutLoggingAdapter(redaction).buildLog(request, response);
        SObject event = helper.get();
        String responseHeaders = (String)event.get('API_Response_Headers__c');

        Assert.areEqual('https://example.com/resource?access_token=[REDACTED]&mode=full', event.get('API_Endpoint__c'));
        Assert.areEqual('POST', event.get('API_Method__c'));
        Assert.areEqual('HttpRequest headers cannot be accessed in bulk', event.get('API_Request_Headers__c'));
        Assert.areEqual('request [REDACTED]', event.get('API_Request_Body__c'));
        Assert.isTrue(responseHeaders.contains('X-Secret=[REDACTED]'));
        Assert.isTrue(responseHeaders.contains('Content-Type=application/json'));
        Assert.isFalse(responseHeaders.contains('response secret'));
        Assert.areEqual('response [REDACTED]', event.get('API_Response_Body__c'));
        Assert.areEqual('request token-123', request.getBody());
        Assert.areEqual('response token-456', response.getBody());
        Assert.areEqual('response secret', response.getHeader('X-Secret'));
        Assert.areEqual('https://example.com/resource?access_token=secret&mode=full', request.getEndpoint());
    }

    @isTest
    public static void rejectsMissingRequest(){
        try {
            new CalloutLoggingAdapter().log(null, new HttpResponse());
            Assert.fail('Expected a missing request to be rejected.');
        } catch (Exception ex) {
            Assert.areEqual('No HttpRequest available to log.', ex.getMessage());
        }
    }
}