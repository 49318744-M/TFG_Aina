from monai.deploy.operators.monai_seg_inference_operator import MonaiSegInferenceOperator
from monai.deploy.core import Application, resource

@resource(cpu=1, gpu=1, memory="4Gi")
class SpleenSegApp(Application):
    def compose(self):
        seg_operator = MonaiSegInferenceOperator(model_path="model.ts")
        self.add_operator(seg_operator)

if __name__ == "__main__":
    SpleenSegApp().execute()


    #commit