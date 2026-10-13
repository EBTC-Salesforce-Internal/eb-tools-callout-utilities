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
    public static void rejectsMissingRequest(){
        try {
            new CalloutLoggingAdapter().log(null, new HttpResponse());
            Assert.fail('Expected a missing request to be rejected.');
        } catch (Exception ex) {
            Assert.areEqual('No HttpRequest available to log.', ex.getMessage());
        }
    }
}