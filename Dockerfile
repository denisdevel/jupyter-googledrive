FROM debian:latest

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 openssl git mercurial subversion && \
    wget --quiet https://repo.continuum.io/archive/Anaconda3-5.1.0-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    conda update -n base conda && \
    apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    cd && git clone https://github.com/jupyterlab/jupyterlab && cd jupyterlab && conda install -c conda-forge jupyterlab && \
    conda install -c conda-forge nodejs && jupyter labextension install @jupyterlab/google-drive && mkdir /etc/openssl && \
    cd /etc/openssl && mkdir ca ca/certs ca/crl ca/newcerts ca/private && chmod 700 ca/private && touch ca/index.txt && echo 1005 > ca/serial && \
    openssl genrsa -out ca/private/ca.key.pem 4096 && chmod 400 ca/private/ca.key.pem && \
    openssl req -key ca/private/ca.key.pem  -new -x509 -days 7300 -extensions v3_ca -out ca/certs/ca.cert.pem  \
    -subj "/C=DE/ST=NRW/L=Berlin/O=My Inc/OU=DevOps/CN=www.example.com/emailAddress=dev@www.example.com" && \
    chmod 444 ca/certs/ca.cert.pem && \
    mkdir jupyter jupyter/csr jupyter/certs jupyter/private && chmod 700 jupyter/private && openssl genrsa -out jupyter/private/ssl.key.pem 2048 && \
    chmod 400 jupyter/private/ssl.key.pem && \
    openssl req -key jupyter/private/ssl.key.pem -new -out jupyter/csr/ssl.csr.pem \ 
    -subj "/C=DE/ST=NRW/L=Berlin/O=My Inc/OU=DevOps/CN=www.example.com/emailAddress=dev@www.example.com" && \
    openssl x509 -req -days 1024 -in jupyter/csr/ssl.csr.pem -out jupyter/certs/ssl.cert.pem  -CA ca/certs/ca.cert.pem -CAkey ./ca/private/ca.key.pem  -CAserial ca/serial && \
    chmod 444 jupyter/certs/ssl.cert.pem && \
    jupyter notebook --generate-config && echo "c.NotebookApp.password = u'sha1:1b68af5d2e91:1ff87c7f16174fcfd39039b0abb4388f2e56cf19'" > /root/.jupyter/jupyter_notebook_config.py && \
    apt-get clean

EXPOSE 8888

CMD [ "jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--certfile=/etc/openssl/jupyter/certs/ssl.cert.pem", "--keyfile=/etc/openssl/jupyter/private/ssl.key.pem"]
