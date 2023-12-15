# コンテナ版IRISを動かしてみよう！
このリポジトリは、2023/12/19開催ウェビナー[「まずはコンテナを動かしてみよう！～コンテナ版IRISで新機能を試す方法のご紹介～」](https://jp.community.intersystems.com/node/553706)で使用した実演環境のファイルなどが含まれています。

※ ウェビナー終了後もオンデマンド配信登録が行えますのでよろしければご参照ください。

リポジトリのサンプルをお試しいただくためにご準備いただく内容は以下の通りです。

- Linux環境
- Docker のインストール

以下2種類の例をお試しいただけます。

1. [pullしたイメージを使ってコンテナを開始する例](#1-pullしたイメージを使ってコンテナを開始する例)
2. [Dockerfileを使用する例](#2-dockerfileを利用する例)

どちらの方法も事前に[InterSystemsコンテナレジストリ](https://containers.intersystems.com/contents)から使用するイメージをpullする必要があります。

- ご参考：[「InterSystemsコンテナレジストリの使い方とコンテナ開始までの流れ（解説ビデオ付き）](https://jp.community.intersystems.com/node/545786)

- メモ：コミュニティエディション**以外**をpullする場合は、開発者コミュニティのアカウント登録が必要です。詳細は[アカウント作成方法](https://jp.community.intersystems.com/node/479221)をご参照ください。

- 実行例は、InterSystems IRIS for Health 最新版のコミュニティエディション（*containers.intersystems.com/intersystems/irishealth-community:latest-cd*）を使用しています。

## 1. pullしたイメージを使ってコンテナを開始する例

以下環境のコンテナを開始します。
![](/assets/docker-run-1.png)


```
docker run --name iriscon1 -d -p 9092:1972 -p 9093:52773 --volume ./data:/data containers.intersystems.com/intersystems/irishealth-community:latest-cd
```

ウェビナーでは2023年12月時点にリリースされている新機能の中から[「Foreing Table（外部テーブル）」](https://docs.intersystems.com/irisforhealthlatestj/csp/docbook/DocBook.UI.Page.cls?KEY=GSQL_tables#GSQL_tables_foreign)を試しています。

> メモ：「Foreing Table（外部テーブル）」は、「試験的機能」の位置づけであるため、実稼働環境での利用はサポートされていませんが、十分なテストがされています。
リリース状況については、[最新版英語ドキュメントの「Foreign Table」](https://docs.intersystems.com/irisforhealthlatest/csp/docbook/DocBook.UI.Page.cls?KEY=GSQL_tables#GSQL_tables_foreign)の記載をご確認ください。

手順は以下の通りです。

- a) [コンテナにログインしIRISのSQLシェルを開く](#a-コンテナにログインしirisのsqlシェルを開く)

- b) [Foreing Tableを使うためにForeign Server定義を作成](#b-foreing-tableを使うためにforeign-server定義を作成)

- c) [CSVファイルに対して Foreign Tableの定義を作成](#c-csvファイルに対して-foreign-tableの定義を作成)

- d) [SELECT文実行](#d-select文実行)

### a) コンテナにログインしIRISのSQLシェルを開く
コンテナ（名前：iriscon1）へのログインは以下の通りです。
```
docker exec -it iriscon1 bash
```
IRISのSQLシェルを開く方法は以下の通りです。

```
iris sql iris
```
> この他、以下のように一旦IRISにログインした後SQLシェルを開く方法もあります。
```
iris session iris
//IRISのプロンプトで以下実行
:sql   //do $SYSTEM.SQL.Shell()と同じ
```

### b) Foreing Tableを使うためにForeign Server定義を作成

コンテナの [/data](/data)　を外部サーバから参照する対象に設定します。
```
CREATE FOREIGN SERVER TryIRIS.FServer FOREIGN DATA WRAPPER CSV HOST '/data'
```

### c) CSVファイルに対して Foreign Tableの定義を作成

定義したForeign Server定義を利用して [/data/person.csv](/data/person.csv) を Foreign Table（外部テーブル）として定義します。

複数行実行モードにシェルを切り替えるため、1度Enterを押してから、以下SQL文をコピーします。実行する場合は go と入力します。
```
CREATE FOREIGN TABLE TryIRIS.Person (
  PID VARCHAR(5),
  Name VARCHAR(20),
  Email VARCHAR(30),
  Tel VARCHAR(15)
) SERVER TryIRIS.FServer FILE 'person.csv'
  USING {"from":{"file":{"charset":"UTF-8","header":true}}}
```

### d) SELECT文実行

※Foreign Tableは内部的にJavaサーバを利用しているため、初回アクセス時、Javaサーバ開始のため少し時間がかかります。
```
select * from TryIRIS.Person
```

 [/data/person.csv](/data/person.csv) ファイルにデータを増やせばそのまま SELECTの結果に反映される事が確認できます。


確認が終わったらSQLシェルを終了します。
```
quit
```
一度IRISにログインしてからSQLシェルを開始した場合は、IRISからログアウトします。（`iris sql iris`でログインした場合はコンテナのプロンプトに戻ります）
```
halt
```
コンテナからのログアウトします。
```
exit
```


## 2. Dockerfileを利用する例

[Dockerfile](/Dockerfile)を使用して、以下のコンテナを実行できるオリジナルのイメージを作成します。

![](/assets//docker-run-Dockerfile.png)

ネームスペースとデータベースの作成に、[Installer.cls](/buildsrc/Installer.cls)を使用しています。（[インストールマニフェスト](https://docs.intersystems.com/irisforhealthlatestj/csp/docbook/DocBook.UI.Page.cls?KEY=GCI_manifest)定義を使用してネームスペース・データベースの作成を行っています。）

このクラス内の処理を実行する命令は、[iris.script](/buildsrc/iris.script)に記載されています。[iris.script](/buildsrc/iris.script)に記載された内容は、[Dockerfile](/Dockerfile)を使用したビルド時にコンテナにコピーされ実行されます。


```
docker image build . --tag myiris:simple
```
作成したイメージでdocker runする例は以下の通りです。
```
docker run --name iriscon2 -d -p 9082:1972 -p 9083:52773 myiris:simple
```

TRYネームスペース・データベース作成と永続クラスTest.Personのインポートと初期データの作成が終了しているか確認します。

コンテナ（iriscon2）にログインします。
```
docker exec -it iriscon2 bash
```

TRYネームスペースにログインします。
```
iris session iris -U TRY
```
SQLシェルに切り替え、Test.Personに対してSELECT文を実行します。
```
:sql

select * from Test.person
```
IRISのプロンプトに戻ります。
```
quit
```

続いて、ビルド時にPythonのモジュールもインストールしているので、Embedded Pythonでモジュールをインポートできるか確認してみます。

（インストールしたモジュール：[requirements.txt](/buildsrc/requirements.txt)）


Pythonシェルを起動（`do ##class(%SYS.Python).Shell()` でも起動できます。）
```
:py
```

以下、インストールしたPythoモジュールを利用して指定のWebページのタイトルを取得してみます。
```
import requests
from bs4 import BeautifulSoup
response=requests.get('https://jp.community.intersystems.com/node/553881')
soup=BeautifulSoup(response.text,'html.parser')
title=soup.find('title').get_text()
title
```
![](/assets/title.png)

Pythonシェルを終了します。
```
quit()
```
IRISをログアウトします。
```
halt
```
コンテナをログアウトします。
```
exit
```

## コンテナ停止と削除

コンテナを停止します。（iriscon1とiriscon2の両方を開始している場合は両方停止しています）
```
docker stop iriscon1
docker stop iriscon2
```

この後コンテナを再開始する場合はここで終了します。
（再開始するときは、`docker start iriscon1` または `docker start iriscon2`　を実行します）

削除してよい場合は、以下実行します。

```
docker rm iriscon1
docker rm iriscon2
```

## 管理ポータルにアクセスする（コミュニティエディションの場合）

管理ポータルにアクセスする場合、コンテナ内の52773番ポートをホストの何番に割り当てているかをご確認ください。

上記説明の [pullしたイメージを使ってコンテナを開始する例](#1-pullしたイメージを使ってコンテナを開始する例) では、9093番、[Dockerfileを使用する例](#2-dockerfileを利用する例)では、9083番に割り当てを行っています。

- iriscon1の場合：　[http://localhost:9093/csp/sys/UtilHome.csp](http://localhost:9093/csp/sys/UtilHome.csp)
- iriscon2の場合：　[http://localhost:9083/csp/sys/UtilHome.csp](http://localhost:9083/csp/sys/UtilHome.csp)

コンテナ版IRISでは、事前定義ユーザ（SuperUser／_SYSTEM）のパスワードがSYS（大文字）に設定されているため、管理ポータル初回アクセス時、このパスワードを変更する画面が表示されます（使用するユーザごとにパスワード変更画面が表示されます）。
![](/assets/portal.png)

iriscon2では、Dockerfileを使用したイメージビルド時に事前定義ユーザのパスワード変更を行わない設定に変更しているため、上記変更画面は表示されません。（SuperUser／_SYSTEMのパスワードはSYSでアクセスできます。）

## VSCodeからIRISにアクセスする

このリポジトリには、VSCodeのワークスペース毎に接続情報を設定できる[settings.json](/.vscode/settings.json)が含まれています。

> IRISの接続情報は、ユーザ単位に設定することもできます。詳しくはコミュニティ記事 [VSCode を使ってみよう (2021年4月20日版)](https://jp.community.intersystems.com/node/493616) をご参照ください。

サーバ接続情報（`intersystems.servers`）は、コンテナと同じ名称で以下のように記載しています。またアクセスするユーザ名に`SuperUser`を設定しています。
```
    "intersystems.servers": {
        "iriscon1": {
            "webServer": {
                "scheme": "http",
                "host":"localhost",
                "port": 9093
            },
            "username": "SuperUser"
        },
        "iriscon2": {
            "webServer": {
                "scheme": "http",
                "host":"localhost",
                "port": 9083
            },
            "username": "SuperUser"
        },
    }
```

接続先の切り替えは、`"objectscript.conn"`の`"server"`の値を変えることで切り替えができます。
```
    "objectscript.conn": {
        "ns": "USER",
        "server": "iriscon1",
        "active": true
    },
```
アクセスするIRISに合わせ、適宜ご変更ください。