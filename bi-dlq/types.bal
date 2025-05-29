
type Message record {|
    string name;
    string data;
|};

type ResponseBody record {|
    string message;
|};

type QueueMessage record {
    Message message;
};
