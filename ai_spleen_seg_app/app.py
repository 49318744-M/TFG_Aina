from monai.deploy.core import Application

class SpleenApp(Application):
    def compose(self):
        pass

if __name__ == "__main__":
    SpleenApp().execute()