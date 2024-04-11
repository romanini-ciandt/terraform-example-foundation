import argparse
from common.components.utils import create_artifact_sample, create_execution_sample, list_artifact_sample

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--serving-container', dest='serving_container')
    parser.add_argument('--model-name', dest='model_name')
    parser.add_argument('--model-dir', dest='model_dir')
    parser.add_argument('--endpoint-name', dest='endpoint_name')
    parser.add_argument('--project', dest='project')
    parser.add_argument('--region', dest='region')
    parser.add_argument('--split', dest='split')
    parser.add_argument('--min-nodes', dest='min_nodes')
    parser.add_argument('--max-nodes', dest='max_nodes')
    parser.add_argument('--service-account', dest='service_account')
    args = parser.parse_args()
    return args


def deploy_model(
        serving_container_image_uri: str,
        model_name: str,
        model_dir: str,
        endpoint_name: str,
        project_id: str,
        region: str,
        split: int,
        min_nodes: int,
        max_nodes: int,
        service_account: str,
        encryption_keyname: str,
        # model: Input[Model],
        # vertex_model: Output[Model],
        # vertex_endpoint: Output[Model]
):
    from google.cloud import aiplatform    
    aiplatform.init(service_account=service_account)
    def create_endpoint():
        endpoints = aiplatform.Endpoint.list(
        filter=f'display_name="{endpoint_name}"',
        order_by='create_time desc',
        project=project_id,
        location=region,
        )
        if len(endpoints) > 0:
            endpoint = endpoints[0] # most recently created
            endpoint_artifact = list_artifact_sample(
                project=project_id,
                location=region,
                display_name_filter="display_name=\"composer_modelendpoint\"",
                order_by="LAST_UPDATE_TIME desc",
            )[0]

        else:
            endpoint = aiplatform.Endpoint.create(
                display_name=endpoint_name,
                project=project_id,
                location=region,
                encryption_spec_key_name=encryption_keyname,
        )   
            endpoint_artifact = create_artifact_sample(
                project=project_id,
                location=region,
                uri=endpoint.resource_name,
                display_name='composer_modelendpoint',
                description='model endpoint created via composer dag',
                metadata={'create_time': endpoint.create_time.strftime("%D %H:%m:%s"),
                          'display_namme': endpoint.display_name,
                          'resource_name': endpoint.resource_name,
                          'update_time': endpoint.update_time.strftime("%D %H:%m:%s")}
            )
        return endpoint, endpoint_artifact

    endpoint, endpoint_artifact = create_endpoint()
    

    def upload_model():
        listed_model = aiplatform.Model.list(
        filter=f'display_name="{model_name}"',
        project=project_id,
        location=region,
        )
        if len(listed_model) > 0:
            model_version = listed_model[0]
            model_upload = aiplatform.Model.upload(
                    display_name=model_name,
                    parent_model=model_version.resource_name,
                    artifact_uri=model_dir,
                    serving_container_image_uri=serving_container_image_uri,
                    location=region,
                    project=project_id,
                    encryption_spec_key_name=encryption_keyname,
            )
        else:
            model_upload = aiplatform.Model.upload(
                    display_name=model_name,
                    artifact_uri=model_dir,
                    serving_container_image_uri=serving_container_image_uri,
                    location=region,
                    project=project_id,
                    encryption_spec_key_name=encryption_keyname
            )

        model_artifact = list_artifact_sample(
            project=project_id,
            location=region,
            display_name_filter="display_name=\"composer_trained_census_model\"",
            order_by="LAST_UPDATE_TIME desc"
        )[0]
        vertexmodel_artifact = create_artifact_sample(
                project=project_id,
                location=region,
                uri=model_upload.uri,
                display_name='composer_vertexmodel',
                description='uploaded vertex model via composer dag',
                metadata={'create_time': model_upload.create_time.strftime("%D %H:%m:%s"),
                          'container_spec': model_upload.container_spec.image_uri,
                          'resource_name': model_upload.resource_name,
                          'update_time': model_upload.update_time.strftime("%D %H:%m:%s"),
                          'version_id': model_upload.version_id},
            )    
        model_upload_event = create_execution_sample(
            display_name='composer_model_upload',
            input_artifacts=[model_artifact],
            output_artifacts=[vertexmodel_artifact],
            project=project_id,
            location=region,
            description='Composer event uploading model to vertex',
        )
        return model_upload, vertexmodel_artifact
    
    uploaded_model, vertexmodel_artifact = upload_model()
    
    
    def deploy_to_endpoint(model, endpoint):
        deployed_models = endpoint.list_models()
        if len(deployed_models) > 0:
            latest_model = sorted(deployed_models, key=lambda x: float(x.model_version_id), reverse=True)[0]
            latest_model_id = latest_model.id
            deployed_endpoint = uploaded_model.deploy(
                # machine_type="n1-standard-4",
                endpoint=endpoint,
                traffic_split={"0": split, latest_model_id: 100-split},
                deployed_model_display_name=model_name,
                min_replica_count=min_nodes,
                max_replica_count=max_nodes,
                encryption_spec_key_name=encryption_keyname
                # service_account="compute default"
            )
        else:
            deployed_endpoint = uploaded_model.deploy(
            # machine_type="n1-standard-4",
            endpoint=endpoint,
            traffic_split={"0": 100},
            min_replica_count=min_nodes,
            max_replica_count=max_nodes,
            deployed_model_display_name=model_name,
            encryption_spec_key_name=encryption_keyname
            # service_account="compute default"
        )
        deployed_endpoint_artifact = create_artifact_sample(
            project=project_id,
            location=region,
            uri=deployed_endpoint.resource_name,
            display_name="composer_deployed_endpoint",
            description='The endpoint with deployed model via composer',
            metadata={'create_time': deployed_endpoint.create_time.strftime("%D %H:%m:%s"),
                        'display_namme': deployed_endpoint.display_name,
                        'resource_name': deployed_endpoint.resource_name,
                        'update_time': deployed_endpoint.update_time.strftime("%D %H:%m:%s"),
                        'traffic_split': deployed_endpoint.traffic_split}
        )
        return deployed_endpoint_artifact

    deploy_model_artifact = deploy_to_endpoint(uploaded_model, endpoint)
    create_execution_sample(
        project=project_id,
        location=region,
        display_name="composer_deploy_event",
        input_artifacts=[vertexmodel_artifact, endpoint_artifact],
        output_artifacts=[deploy_model_artifact],
        description="Composer event deploying model to endpoint"
    )


    
if __name__=="__main__":
    args = get_args()
    deploy_model(
        serving_container_image_uri=args.serving_container,
        model_name=args.model_name,
        model_dir=args.model_dir,
        endpoint_name=args.endpoint_name,
        project_id=args.project_id,
        region=args.region,
        split=args.split,
        min_nodes=args.min_nodes,
        max_nodes=args.max_nodes,
        service_account=args.service_account,
)
