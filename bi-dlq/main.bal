import ballerina/data.jsondata;
import ballerina/http;
import ballerina/log;
import ballerinax/rabbitmq;

listener http:Listener httpDefaultListener = http:getDefaultListener();

service /api/v1 on httpDefaultListener {
    resource function post messages(@http:Payload Message message) returns http:Response|error|MessageAccepted {
        do {
            log:printInfo("received a message at the http service", content = message);
            anydata content = {message: message};
            string queueName = "messages.bi";
            rabbitmq:AnydataMessage anydataMsg = {content: content, routingKey: queueName};
            log:printInfo("publishing the message to the target queue");
            check rabbitmqClient->publishMessage(anydataMsg);
            MessageAccepted acceptedRes = {body: {message: "message has been accepted"}};
            return acceptedRes;
        } on fail error err {
            log:printError("error occurred while publishing the message", err);
            return err;
        }
    }
}

public type MessageAccepted record {|
    *http:Accepted;
    ResponseBody body;
|};

listener rabbitmq:Listener rabbitMQListener = new (host = "localhost", port = 5672);

@rabbitmq:ServiceConfig {
    queueName: "messages.bi",
    config: {
        durable: true,
        autoDelete: false
    }
}
service rabbitmq:Service "messages.bi" on rabbitMQListener {
    remote function onMessage(rabbitmq:AnydataMessage message, rabbitmq:Caller caller) returns error? {
        do {
            log:printInfo("message received at the queue", content = message);
            anydata actualContent = message.content;
            Message messageContent;
            if actualContent is byte[] {
                string stringContent = check string:fromBytes(actualContent);
                QueueMessage queueMsg = check jsondata:parseString(stringContent);
                messageContent = queueMsg.message;
            } else {
                error err = error("content is not a byte array");
                log:printError("error occurred while extracting the message content", err);
                return err;
            }
            log:printInfo("sending the message to the HTTP endpoint");
            json response = check httpClient->post("/messages", messageContent);
            log:printInfo("response received from the HTTP endpoint", content = response);

        } on fail error err {
            log:printError("error occurred while processing the message", err);
            anydata actualContent = message.content;
            string messageContent = "unknown";
            if actualContent is byte[] {
                string stringContent = check string:fromBytes(actualContent);
                messageContent = stringContent;
            }
            anydata content = {message: messageContent, errorMessage: err.message(), errorStackTrace: err.stackTrace().toString()};
            string queueName = "messages.bi.dlq";
            rabbitmq:AnydataMessage anydataMsg = {content: content, routingKey: queueName};
            log:printInfo("sending the message to the dead-letter queue");
            check rabbitmqClient->publishMessage(anydataMsg);
        }
    }

    remote function onError(rabbitmq:AnydataMessage message, rabbitmq:Error rabbitmqError) returns error? {
        do {
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }
}
