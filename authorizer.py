import os
import jwt
import urllib
import json

from cryptography.hazmat.backends import default_backend
from cryptography.x509 import load_pem_x509_certificate

def handler(event, context):
    authorization_header_value = event['headers']['Authorization']
    print("Authorization header value: " + authorization_header_value)

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
    
    token = token_parts[1]
    
    #TODO:check the signature algo?
    response  = urllib.urlopen('https://thithimos.auth0.com/.well-known/jwks.json')
    res = response.read()
    print('response:')
    print(res)
    jwks = json.loads(res)
    print('jwks:')
    print(jwks)
    unverified_header = jwt.get_unverified_header(token)
    print('unverified_header:')
    print(unverified_header)

    rsa_key = {}
    public_key = ''
    for key in jwks["keys"]:
        if key["kid"] == unverified_header["kid"]:
            rsa_key = {
                "kty": key["kty"],
                "kid": key["kid"],
                "use": key["use"],
                "n": key["n"],
                "e": key["e"]
            }
            public_key = key['x5c'][0]

    if rsa_key:
        try:
            principal_id = jwt_verify(token, public_key)
        except jwt.ExpiredSignatureError:
            print('token expired')
            raise Exception('Unauthorized')
        except jwt.MissingRequiredClaimError:
            print('missing required claim')
            raise Exception('Unauthorized')
        except jwt.DecodeError:
            print('decode error')
            raise Exception('Unauthorized')
        except jwt.InvalidTokenError as e:
            print('invalid token error:')
            print(e)
            raise Exception('Unauthorized')
        except Exception as e:
            print('invalid header - unable to parse authentication token:')
            print(e)
            raise Exception('Unauthorized')

        policy = generate_policy(principal_id, 'Allow', event['methodArn'])
        return policy
        
    print('unable to find appropriate key')
    raise Exception('Unauthorized')

    #TODO:check the permissions

def jwt_verify(auth_token, public_key):
    public_key = format_public_key(public_key)
    pub_key = convert_certificate_to_pem(public_key)
    payload = jwt.decode(auth_token, pub_key, algorithms=['RS256'], audience='https://api-cancel-auth.tripsource.com')
    return payload['sub']


def format_public_key(public_key):
    return '-----BEGIN CERTIFICATE-----\n' + public_key + '\n-----END CERTIFICATE-----'


def convert_certificate_to_pem(public_key):
    cert_str = public_key.encode()
    cert_obj = load_pem_x509_certificate(cert_str, default_backend())
    pub_key = cert_obj.public_key()
    return pub_key


def generate_policy(principal_id, effect, resource):
    return {
        'principalId': principal_id,
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
