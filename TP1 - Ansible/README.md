# TP1 : Ansible

Le but de ce TP est d'approfondir l'utilisation d'Ansible :

- construction de playbooks
- organisation de dépôt
- workflow de travail

> Il est strictement nécessaire d'avoir terminé les [TP0](../0/README.md) et [TP1](../1/README.md).

# Sommaire

- [TP1 : Ansible](#tp1--ansible)
- [Sommaire](#sommaire)
- [0. Setup](#0-setup)
- [I. Init repo](#i-init-repo)
- [II. Un dépôt Ansible rangé](#ii-un-dépôt-ansible-rangé)
  - [1. Structure du dépôt : inventaires](#1-structure-du-dépôt--inventaires)
  - [2. Structure du dépôt : rôles](#2-structure-du-dépôt--rôles)
  - [3. Structure du dépôt : variables d'inventaire](#3-structure-du-dépôt--variables-dinventaire)
  - [4. Structure du dépôt : rôle avancé](#4-structure-du-dépôt--rôle-avancé)
- [III. Repeat](#iii-repeat)
  - [1. NGINX](#1-nginx)
  - [2. Common](#2-common)
  - [3. Dynamic loadbalancer](#3-dynamic-loadbalancer)
- [IV. Bonus : Aller plus loin](#iv-bonus--aller-plus-loin)
  - [1. Vault Ansible](#1-vault-ansible)
  - [2. Support de plusieurs OS](#2-support-de-plusieurs-os)

# 0. Setup

Pour réaliser le TP vous allez avoir besoin de :

- 1 poste avec Ansible : **le *control node***
  - votre PC sous Linux (ou Windows + folies avec WSL par ex), ou une VM sous Linux
  - le fichier `hosts` de cette machine doit être rempli pour pouvoir joindre les deux *managed nodes* avec des noms plutôt qu'une IP :
    - `node1.tp2.cloud`
    - `node2.tp2.cloud`
- 2 machines Linux : **les *managed nodes***
  - déployées avec Vagrant

Une fois les machines en place, assurez-vous que vous avez avoir une connexion SSH sans mot **de passe depuis le *control node* vers les *managed nodes***.

# I. Init repo

![Git init](./pics/git_init.jpg)

➜ **Créez un répertoire de travail**

- sur le *control node*
- dans le *home directory* de l'utilisateur que vous utilisez
- ce répertoire doit être un dépôt git que vous avez créé sur une plateforme publique comme Gitlab, Github, etc.
  - vous pouvez cloner et utiliser un seul dépôt git pour tous les cours
  - veillez à bien séparer votre travail et créer un répertoire dédié pour ce nouveau TP

> **Tous les fichiers Ansible devront être créés dans de dossier.**

➜ **Créez le fichier d'inventaire Ansible**

- référez-vous au [TP0](../0/README.md)
- créez un fichier *inventory* `hosts.ini`
  - nommez le groupe d'hôtes `ynov`
  - les instructions du TP utiliseront `ynov` comme nom de groupe
- utilisez le module `ping` de Ansible pour tester qu'Ansible peut joindre les machines

```bash
$ ansible ynov -i hosts.ini -m ping 
```

➜ **Créez un playbook de test**

- dans le répertoire de travail Ansible, créez un sous-répertoire `playbooks/`
- créez un fichier `playbooks/test.yml`
- écrire le nécessaire dans le fichier pour installer `vim` sur les *managed nodes*
  - référez-vous au [fichier `nginx.yml` du TP0](./../0/README.md#1-un-premier-playbook)

# II. Un dépôt Ansible rangé

## 1. Structure du dépôt : inventaires

➜ **Dans votre répertoire de travail Ansible...**

- créez un répertoire `inventories/`
- créez un répertoire `inventories/vagrant_lab/`
- déplacez le fichier `hosts.ini` dans `inventories/vagrant_lab/hosts.ini`
- assurez vous que pouvez toujours déployer correctement avec une commande `ansible-playbook`

## 2. Structure du dépôt : rôles

**Les *rôles* permettent de regrouper de façon logique les différentes configurations qu'un dépôt Ansible contient.**

Un *rôle* correspond à une configuration spécifique, ou une application spéficique. Ainsi on peut trouver un rôle `apache` qui installe le serveur web Apache, ou encore `mysql`, `nginx`, etc.

**Un rôle doit être générique.** Il ne doit pas être spécifique à telle ou telle machine.

Il existe des conventions et bonnes pratiques pour structurer les *rôles* Ansible, que nous allons voir dans cette partie.

On crée souvent un *rôle* `common` qui est appliqué sur toutes les machines du parc, et qui pose la configuration élémentaire, commune à toutes les machines.

➜ **Ajout d'un fichier de config Ansible**

- dans le répertoire de travail, créez un fichier `ansible.cfg` :

```ini
[defaults]
roles_path = ./roles
```

➜ **Dans votre répertoire de travail Ansible...**

- créez un répertoire `roles/`
- créez un répertoire `roles/common/`
- créez un répertoire `roles/common/tasks/`
- créez un fichier `roles/common/tasks/main.yml` avec le contenu suivant :

```yml
- name: Install common packages
  import_tasks: packages.yml
```

- créez un fichier `roles/common/tasks/packages.yml` :
  - on va en profiter pour manipuler des variables Ansible

```yml
- name: Install common packages
  ansible.builtin.package:
    name: "{{ item }}"
    state: present
  with_items: "{{ common_packages }}" # ceci permet de boucler sur la liste common_packages
```

- créez un répertoire `roles/common/defaults/`
- créez un fichier `roles/common/defaults/main.yml` :

```yml
common_packages:
  - vim
  - git
```

- créez un fichier `playbooks/main.yml`

```yml
- hosts: ynov
  roles:
    - common
```

➜ **Testez d'appliquer ce playbook avec une commande `ansible-playbook`**

## 3. Structure du dépôt : variables d'inventaire

Afin de garder la complexité d'un dépôt Ansible sous contrôle, il est récurrent d'user et abuser de l'utilisation des variables.

Il est possible dans un dépôt Ansible de déclarer à plusieurs endroits : on a déjà vu le répertoire `defaults/` à l'intérieur d'un rôle (comme notre `roles/common/defaults/`) que l'on a créé juste avant. Ce répertoire est utile pour déclarer des variables spécifiques au rôle.

Qu'en est-il, dans notre cas présent, si l'on souhaite installer un paquet sur une seule machine, mais qui est considéré comme un paquet de "base" ? On aimerait l'ajouter dans la liste dans `roles/common/defaults/main.yml` mais ce serait moche d'avoir une condition sur le nom de la machine à cet endroit (un rôle doit être générique).

**Pour cela on utilise les `host_vars`.**

➜ **Dans votre répertoire de travail Ansible...**

- créez un répertoire `inventories/vagrant_lab/host_vars/`
- créez un fichier `inventories/vagrant_lab/host_vars/node1.tp2.cloud.yml` :

```yml
common_packages:
  - vim
  - git
  - rsync
```

➜ **Testez d'appliquer le playbook avec une commande `ansible-playbook`**

---

Il est aussi possible d'attribuer des variables à un groupe de machines définies dans l'inventaire. **On utilise pour ça les `group_vars`.**

➜ **Dans votre répertoire de travail Ansible...**

- créez un répertoire `inventories/vagrant_lab/group_vars/`
- créez un fichier `inventories/vagrant_lab/group_vars/ynov.yml` :

```yml
users:
  - le_nain
  - l_elfe
  - le_ranger
```

➜ **Modifiez le fichier `roles/common/tasks/main.yml`** pour inclure un nouveau fichier  `roles/common/tasks/users.yml` :

- il doit utiliser cette variable `users` pour créer des utilisateurs
- réutilisez la syntaxe avec le `with_items`
- la variable `users` est accessible, du moment que vous déployez sur les machines qui sont dans le groupe `ynov`

➜ **Vérifiez la bonne exécution du playbook**

## 4. Structure du dépôt : rôle avancé

➜ **Créez un nouveau rôle `nginx`**

- créez le répertoire du rôle `roles/nginx/`
- créez un sous-répertoire `roles/nginx/tasks/` et un fichier `main.yml` à l'intérieur :

```yml
- name: Install NGINX
  import_tasks: install.yml

- name: Configure NGINX
  import_tasks: config.yml

- name: Deploy VirtualHosts
  import_tasks: vhosts.yml
```

➜ **Remplissez le fichier `roles/nginx/tasks/install.yml`**

- il doit installer le paquet NGINX
  - je vous laisse gérer :)

➜ **On va y ajouter quelques mécaniques : fichiers et templates :**

- créez un répertoire `roles/nginx/files/`
- créez un fichier `roles/nginx/files/nginx.conf`
  - récupérez un fichier `nginx.conf` par défaut (en faisant une install à la main par exemple)
  - ajoutez une ligne `include conf.d/*.conf;`
- créez un répertoire `roles/nginx/templates/`
- créez un fichier `roles/nginx/templates/vhost.conf.j2` :
  - `.j2` c'pour Jinja2, c'est le nom du moteur de templating utilisé par Ansible

```nginx
server {
        listen {{ nginx_port }} ;
        server_name {{ nginx_servername }};

        location / {
            root {{ nginx_webroot }};
            index index.html;
        }
}
```

➜ **Remplissez le fichier `roles/nginx/tasks/config.yml`** :

```yml
- name : Main NGINX config file
  copy:
    src: nginx.conf # pas besoin de préciser de path, il sait qu'il doit chercher dans le dossier files/
    dest: /etc/nginx/nginx.conf
```

➜ **Quelques variables `roles/nginx/defaults/main.yml`** :

```yml
nginx_servername: test
nginx_port: 8080
nginx_webroot: /var/www/html/test
nginx_index_content: "<h1>teeeeeest</h1>"
```

➜ **Remplissez le fichier `roles/nginx/tasks/vhosts.yml`** :

```yml
- name: Create webroot
  file:
    path: "{{ nginx_webroot }}"
    state: directory

- name: Create index
  copy:
    dest: "{{ nginx_webroot }}/index.html"
    content: "{{ nginx_index_content }}"

- name: NGINX Virtual Host
  template:
    src: vhost.conf.j2
    dest: /etc/nginx/conf.d/{{ nginx_servername }}.conf
```

➜ **Deploy !**

- ajoutez ce rôle `nginx` au playbook
- et déployez avec une commande `ansible-playbook`

![That feel](./pics/that_feel.jpg)

# III. Repeat

## 1. NGINX

➜ **On reste dans le rôle `nginx`**, faites en sorte que :

- on puisse déclarer la liste `vhosts` en *host_vars*
- si cette liste contient plusieurs `vhosts`, le rôle les déploie tous (exemple en dessous)
- le port précisé est automatiquement ouvert dans le firewall
- vous gérez explicitement les permissions de tous les fichiers

Exemple de fichier de variable avec plusieurs Virtual Hosts dans la liste `vhosts` :

```yml
vhosts:
  - test2:
    nginx_servername: test2
    nginx_port: 8082
    nginx_webroot: /var/www/html/test2
    nginx_index_content: "<h1>teeeeeest 2</h1>"
  - test3:
    nginx_servername: test3
    nginx_port: 8083
    nginx_webroot: /var/www/html/test3
    nginx_index_content: "<h1>teeeeeest 3</h1>"
```

➜ **Ajoutez une mécanique de `handlers/`**

- c'est un nouveau dossier à placer dans le rôle
- je vous laisse découvrir la mécanique par vous-mêmes et la mettre en place
- vous devez trigger un *handler* à chaque fois que la conf NGINX est modifiée
- vérifiez le bon fonctionnement
  - vous pouvez voir avec un `systemctl status` depuis quand une unité a été redémarrée

## 2. Common

➜ **On revient sur le rôle `common`**, les utilisateurs déployés doivent** :

- avoir un password
- avoir un homedir
- avoir accès aux droits de `root` *via* `sudo`
- être dans un groupe `admin`
- avoir une clé SSH publique déposé dans leur `authorized_keys`

> Toutes ces données doivent être stockées dans les `group_vars`.

## 3. Dynamic loadbalancer

➜  **Créez un nouveau rôle : `webapp`**

- ce rôle déploie une application Web de votre choix, peu importe
- elle déploie aussi le serveur web nécessaire pour que ça tourne
  - vous pouvez clairement réutiliser le rôle NGINX d'avant qui déploie une bête page HTML

> Vraiment, peu importe, une bête page HTML, ou un truc open source comme un NextCloud. Ce qu'on veut, c'est simplement une interface visible.

➜  **Créez un nouveau rôle : `rproxy` (pour *reverse proxy*)**

- ce rôle déploie un NGINX
- NGINX est automatiquement configuré pour agir comme un reverse proxy vers une liste d'IP qu'on lui fournit en variables
  - à priori, vous allez gérer ça avec des `host_vars` et `group_vars`

➜ **Effectuez le déploiement suivant :**

- deux machines portent le rôle `webapp`
- une machine porte le rôle `rproxy`

> **Il sera nécessaire d'ajouter une nouvelle VM à votre déploiement Vagrant !**

- faites en sorte que :
  - si on déploie une nouvelle machine qui porte le rôle `webapp`, la conf du reverse proxy se met à jour en fonction
  - si on supprime une machine `webapp`, la conf du reverse proxy se met aussi à jour en fonction

> La configuration de votre loadbalancer devient dynamique, et plus aucune connexion manuelle n'est nécessaire pour ajuster la taille du parc en fonction de la charge.

➜ **Exemple de configuration NGINX** qui effectue un loadbalancing entre deux machines serveurs Web qui portent les IP `192.168.56.102` et `192.168.56.103` (ce fichier est à placer dans le dossier `/etc/nginx/conf.d/` et doit porter l'extension `.conf` afin d'être inclus par le fichier `/etc/nginx/nginx.conf`) :

```NGINX
upstream super_application {
    server 192.168.56.102;
    server 192.168.56.103;
}

server {
    server_name anyway.com;

    location / {
        proxy_pass http://super_application;
        proxy_set_header    Host $host;
    }
}
```


# IV. Bonus : Aller plus loin

## 1. Vault Ansible

Afin de ne pas stocker de données sensibles en clair dans les fichiers Ansible, comme des mots de passe, on peut utiliser les [vault Ansible](https://docs.ansible.com/ansible/latest/user_guide/vault.html).

Cela permet de stocker ces données, mais dans des fichiers chiffrés, à l'intérieur du dépôt Ansible.

➜ **Utilisez les Vaults pour stocker les clés publiques des utilisateurs**

## 2. Support de plusieurs OS

**Il est possible qu'un rôle donné fonctionne pour plusieurs OS.** Pour ça, on va utiliser des conditions en fonction de l'OS de la machine de destination.

A chaque fois qu'on déploie de la conf sur une machine, cette dernière nous donne beaucoup d'informations à son sujet : ses ***facts***. Par exemple, on récupère la liste des cartes réseau de la machine, la liste des utilisateurs, l'OS utilisé, etc.

On peut alors récupérer ces variables dans nos tasks, pour les insérer dans des templates par exemple, ou encore effectuer du travail conditionnel :

```yml
  - name: Install apache
    apt: 
      name: apache
      state: latest
    when: ansible_distribution == 'Debian' or ansible_distribution == 'Ubuntu'

  - name: Install apache
    yum: 
      name: httpd # le nom du paquet est différent sous CentOS
      state: latest
    when: ansible_distribution == 'CentOS'
```

➜ **Ajoutez une machine d'un OS différent à votre `Vagrantfile` et adaptez vos playbooks**

- passez sur une CentOS si vous étiez sur une base Debian jusqu'alors
- ou vice-versa

![It's a fucking art](./pics/its_a_fucking_art.jpg)
