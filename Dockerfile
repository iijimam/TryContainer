#イメージのタグはこちら（https://containers.intersystems.com/contents）でご確認ください
ARG IMAGE=containers.intersystems.com/intersystems/irishealth-community:latest-cd
FROM $IMAGE

USER root
# コンテナ内のワークディレクトリを /opt/try　に設定（後でここにデータベースを作成予定）
WORKDIR /opt/try
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/try

USER ${ISC_PACKAGE_MGRUSER}

# ファイルのコピー
COPY buildsrc/ .
COPY src src

# iris.scriptに記載された内容を実行
RUN iris start IRIS \
	&& iris session IRIS < iris.script \
    && iris stop IRIS quietly \
    ## pipでPythonモジュールインストール
    && pip install -r requirements.txt
