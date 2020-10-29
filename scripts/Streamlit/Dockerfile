FROM ubuntu:bionic
USER root

# Install dependencies
RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository universe
RUN apt-get update && apt-get install -y curl python3.6 python3-pip

# Install Streamlit
RUN pip3 install --upgrade pip && pip3 install streamlit pandas numpy matplotlib scikit-learn

# Copy File Over
COPY main.py main.py

ENV LANG C.UTF-8

# Run Application
CMD streamlit run main.py --server.port 80