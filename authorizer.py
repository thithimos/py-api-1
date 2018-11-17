import os

def handler(event, context):
    authorization_header_value = event['headers']['Authorization']
    print(f"Authorization header value: {authorization_header_value}")

    if not authorization_header_value:
        raise Exception('Unauthorized')
    
    token_parts = authorization_header_value.split(' ')

    if not token_parts[0].lower() == 'bearer':
        print('Token method is invalid')
        raise Exception('Unauthorized')
    elif len(token_parts) == 1:
        print('Token not found')
        raise Exception('Unauthorized')
    elif len(token_parts) > 2:
        print('Invalid authorization header value')
        raise Exception('Unauthorized')
    
    policy = generate_policy('Allow', event['methodArn'])
    return policy


def generate_policy(effect, resource):
    return {
        #'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": effect,
                    "Resource": resource

                }
            ]
        }
    }
