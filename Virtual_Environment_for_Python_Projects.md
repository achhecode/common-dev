1. Navigate to your project folder

Open your terminal and move into your project directory:
```sh
cd path/to/your/project
```
2. Create a virtual environment

Run:
```sh
python -m venv venv
#or
python3 -m venv venv
```

python (or python3) is your Python interpreter.

venv is the name of the virtual environment folder (you can name it anything, but venv is common).

This will create a new directory called venv/ inside your project with a local Python installation.

3. Activate the virtual environment

On macOS/Linux:
```sh
source venv/bin/activate
```

On Windows (PowerShell):
```sh
.\venv\Scripts\Activate
```

Once activated, you’ll see (venv) appear at the start of your terminal prompt.

4. Install dependencies

Now you can install packages without affecting your global Python setup:
```sh
pip install requests flask
```
5. Save dependencies (optional)

To record your dependencies for later use:
```sh
pip freeze > requirements.txt
```
6. Deactivate the environment

When you’re done working:
```sh
deactivate
```
