FROM ubuntu:20.04

ARG HUGO_VERSION=0.74.3
ENV DOCUMENT_DIR=/hugo-project

ARG asciidoctor_version=2.0.10
ARG asciidoctor_pdf_version=1.5.0.rc.1
ARG asciidoctor_diagram_version=2.0.0
ARG asciidoctor_mathematical_version=0.3.1
ARG asciidoctor_bibtex=0.7.1

ENV ASCIIDOCTOR_VERSION=${asciidoctor_version} \
  ASCIIDOCTOR_PDF_VERSION=${asciidoctor_pdf_version} \
  ASCIIDOCTOR_DIAGRAM_VERSION=${asciidoctor_diagram_version} \
  ASCIIDOCTOR_MATHEMATICAL_VERSION=${asciidoctor_mathematical_version} \
  ASCIIDOCTOR_BIBTEX_VERSION=${asciidoctor_bibtex}


RUN apt-get update && apt-get upgrade -y \
      && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
           ruby ruby-dev make cmake build-essential bison flex git \
           software-properties-common pandoc graphviz \
           python3-dev python3-pip python3-setuptools \
           default-jre curl libffi-dev libxml2-dev \
           libgdk-pixbuf2.0-dev libcairo2-dev libpango1.0-dev \
          fonts-lyx gnupg \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/* \
      && rm -rf /tmp/*

# install nodejs for compiling stylesheets
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -E \

  && apt-get -y install nodejs

# Installing Ruby Gems needed in the image
# including asciidoctor itself
RUN gem install --no-document --pre \
    "asciidoctor:${ASCIIDOCTOR_VERSION}" \
    "asciidoctor-diagram:${ASCIIDOCTOR_DIAGRAM_VERSION}" \
    "asciidoctor-pdf:${ASCIIDOCTOR_PDF_VERSION}" \
    "asciidoctor-mathematical:${ASCIIDOCTOR_MATHEMATICAL_VERSION}" \
    "asciidoctor-bibtex:${ASCIIDOCTOR_BIBTEX_VERSION}" \
    coderay \
    bundler \
    rack \
    asciimath 
    
# Installing Python dependencies for additional
# functionalities as diagrams or syntax highligthing
RUN  pip3 install --no-cache-dir \
    actdiag \
    'blockdiag[pdf]' \
    nwdiag \
    seqdiag
  
# install custom version of rouge from repo (with msdl highlighting)
RUN cd /opt \
  && git clone https://github.com/engelben/rouge.git \
  && bundle config --global silence_root_warning 1 \
  && cd rouge \
  && bundle install --path vendor \
  && bundler exec rake build \
  && gem install ./pkg/rouge-3.14.0.gem


# install plantuml
RUN mkdir -p /opt/plantuml \
  && cd /opt/plantuml \
  && curl -JLO http://sourceforge.net/projects/plantuml/files/plantuml.jar/download \
  && touch /usr/local/bin/plantuml \
  && echo "#!/bin/sh" >> /usr/local/bin/plantuml \
  && echo  'java -jar /opt/plantuml/plantuml.jar "\$@"' >> /usr/local/bin/plantuml \
  && chmod a+x /usr/local/bin/plantuml


# install asciidoctor stylesheet factory
RUN cd /opt \
  && git clone https://github.com/engelben/asciidoctor-stylesheet-factory.git \
  && cd asciidoctor-stylesheet-factory \
  && bundle \
  && npm i \
  && compass compile 

ENV TZ=Europe/Berlin
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    tzdata \
    && dpkg-reconfigure --frontend noninteractive tzdata



ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz /tmp/hugo.tgz

RUN cd /usr/local/bin && tar -xzf /tmp/hugo.tgz && rm /tmp/hugo.tgz

RUN mkdir ${DOCUMENT_DIR}
WORKDIR ${DOCUMENT_DIR}

VOLUME ${DOCUMENT_DIR}

CMD ["hugo","server","--bind","0.0.0.0"]