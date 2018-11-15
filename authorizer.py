def handler(event, context):
    print("Client token: " + event['headers']['authorization'])
    raise Exception('Unauthorized')
