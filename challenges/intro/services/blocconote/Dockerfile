FROM python:3.13.2-alpine3.21

ADD requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

ADD src /app

WORKDIR /app

CMD ["flask", "run", "--host", "0.0.0.0"]
