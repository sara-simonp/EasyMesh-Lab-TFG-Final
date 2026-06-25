FROM python:3.11-slim

WORKDIR /app

COPY app.py /app/app.py

ENV SIM_PORT=9200
ENV DATA_DIR=/data
ENV WRITE_TR181_CSV=1
ENV DEFAULT_SCENARIO=normal
ENV RANDOM_SEED=2526

EXPOSE 9200

CMD ["python", "/app/app.py"]
