import os
import json
import boto3
from datetime import datetime, timedelta
import urllib.request
import io
import zipfile
import logging


logger = logging.getLogger()
logger.setLevel(logging.INFO)


sns_client = boto3.client('sns')
logs_client = boto3.client('logs')
lambda_client = boto3.client('lambda')
bedrock_client_retrive = boto3.client('bedrock-agent-runtime', region_name="us-west-2")
bedrock_client_invoke = boto3.client('bedrock-runtime', region_name="us-west-2")

LOG_GROUP_NAME = os.getenv('LOG_GROUP_NAME')
SNS_TOPIC_ARN = os.getenv('TOPIC_ARN')
LAMBDA_FUNCTION_NAME = os.environ['LAMBDA_FUNCTION_NAME']
KB_ID = os.getenv('KB_ID')
MODEL_ID = os.getenv('MODEL_ID')


def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        if 'header' in event and 'message' in event:
            header = event.get('header', 'No header')
            message = event.get('message', 'No message')
            
            # Ottieni i log di errore e il codice Lambda
            error_logs = get_recent_error_logs(LOG_GROUP_NAME)
            lambda_code = get_lambda_code()

            error_identification = f"Can you isolate the single error in this log: {error_logs}? "
            error_id = get_solution_invoke(error_identification)
            logger.info({error_id})

            error_description = f"Can you describe this error {error_id} and give me a pratical example of this error?"
            error_desc = get_solution_invoke(error_description)
            logger.info({error_desc})

            error_retirve= f"I have this error {error_desc}, can you find this in documentation?"
            error_re = get_solution_retrive(error_retirve)
            logger.info({error_re})

            detailed_message = f"{error_id} \n {error_desc} \n {error_re}"

            """ mid_query = f"A Lambda code caused these errors: {error_id} why?"
            query1 = f"The following Lambda code: {lambda_code} caused these errors: {error_logs} why?"
            
            logger.info({query1})
            logger.info({mid_query})

            mid_solution = get_solution_retrive(mid_query)
            logger.info({mid_solution})
            
            solution1 = get_solution_invoke(query1)
            logger.info({solution1})
            
            query2 = f"The lambda code: {lambda_code} \n caused an error: {error_logs} \n and from the documentation you retrive: {mid_solution}, can you explain me more?"
            
            solution2 = get_solution_invoke(mid_solution)
            logger.info({solution2})
            
            detailed_message = f"{message}\n\nDettagli errore:\n{error_logs}\n\nPossibili soluzioni:\n 1. {solution1}. \n 2.{mid_solution}. \n 3. {solution2}. The single error is: {error_id} "
             """
            
            logger.info(f"Publishing message to SNS Topic: {SNS_TOPIC_ARN}")
            response = sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=header,
                Message=detailed_message
            )
            
            logger.info(f"SNS Publish Response: {response}")
        else:
            raise ValueError("Unknown event.")
        
        return {
            'statusCode': 200,
            'body': json.dumps('SUCCESS')
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps('ERROR ' + str(e))
        }


def get_recent_error_logs(log_group_name):
    # Correct timestamp calculation
    end_time = int(datetime.now().timestamp() * 1000)
    start_time = int((datetime.now() - timedelta(minutes=15)).timestamp() * 1000)
    
    logger.info(f"Querying log group: {log_group_name}")
    logger.info(f"Start time: {start_time}, End time: {end_time}")
    
    try:
        response = logs_client.filter_log_events(
            logGroupName=log_group_name,
            startTime=start_time,
            endTime=end_time,
            filterPattern='?ERROR ?Exception ?Traceback'
        )
        
        logger.info(f"CloudWatch response: {response}")

        error_messages = [event['message'] for event in response['events']]
        
        if error_messages:
            return "\n".join(error_messages)
        else:
            return "NO ERROR"
        
    except Exception as e:
        logger.error(f"LOG ERROR: {e}")
        return f"LOG ERROR: {str(e)}"
        
#Recupero dei dati dai file
def get_solution_retrive(query):
    try:
        response = bedrock_client_retrive.retrieve(
            knowledgeBaseId=KB_ID,
            retrievalQuery={'text': query},
            retrievalConfiguration={"vectorSearchConfiguration": {"numberOfResults": 1}}
        )
        
        results = response.get('retrievalResults', [])
        logger.info(f"Bedrock retrieve: {response}")

        if results:
            return f"Risposta con retrieve: {results[0].get('content', 'No content')}"
        else:
            return "NO RESULT"

    except Exception as e:
        logger.error(f"Bedrock retrieve error: {str(e)}")
        return f"ERROR: {str(e)}"
        
#Risposta generata
def get_solution_invoke(query):
    try:
        response = bedrock_client_invoke.converse(
            modelId=MODEL_ID, 
            messages=[{
                "role": "user",
                "content": [{"text": query}]
                }],
            inferenceConfig={"maxTokens": 512, "temperature": 0.0, "topP": 1.0}
        )
        
        logger.info(f"Bedrock invoke: {response}")
        
        response_text = response["output"]["message"]["content"][0]["text"]
        logger.info(f"Bedrock invoke: {response_text}")
        
        return f"Risposta con invoke: {response_text}"
    
    except Exception as e:
        logger.error(f"Bedrock invoke error: {str(e)}")
        return f"ERROR: {str(e)}"
        

def get_lambda_code():
    try:
        response = lambda_client.get_function(
            FunctionName=LAMBDA_FUNCTION_NAME
        )
        location = response['Code']['Location']
        
        with urllib.request.urlopen(location) as url:
            zip_content = url.read()
        
        with zipfile.ZipFile(io.BytesIO(zip_content)) as zip_ref:
            lambda_code = zip_ref.read('dynamoDB_lambda.py').decode('utf-8')
        
        return lambda_code
    except Exception as e:
        print(f"Errore nel recupero Lambda: {str(e)}")
        return "Lambda error."
