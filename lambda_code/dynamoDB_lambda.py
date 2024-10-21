import json
import os
import boto3
import pandas as pd
import logging
from botocore.exceptions import BotoCoreError, ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    
    table_name = os.environ['DYNAMODB_TABLE_NAME']

    try:

        dynamodb_client = boto3.resource("dynamodb", region_name="eu-west-1")
        table = dynamodb_client.Table(table_name)
        
        scan = table.scan(ProjectionExpression="WorkName")
        data = scan['Items']
        
        while 'LastEvaluatedKey' in scan:
            scan = table.scan(ExclusiveStartKey=scan['LastEvaluatedKey'], ProjectionExpression="WorkName")
            data.extend(response['Items'])
            
        dataframe = pd.DataFrame(data)
        
        for WorkName in dataframe['WorkName']:
            print ('WorkName:', WorkName)
            
        item = {
            'Author': 'Ugo Foscolo'
        }
        
        table.put_item(Item=item)
    
    except (BotoCoreError, ClientError) as e:
        logger.error(f"DynamoDB error: {str(e)}")
        raise
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f"ERROR {str(e)}")
        }
