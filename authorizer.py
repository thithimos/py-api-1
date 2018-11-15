def handler(event, context):
    print("Client token: " + event['authorizationToken'])
    raise Exception('Unauthorized')
