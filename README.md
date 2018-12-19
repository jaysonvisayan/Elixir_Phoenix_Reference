[![build status](https://gitlab.medilink.com.ph/open-source-team/innerpeace_umbrella/badges/master/build.svg)](https://gitlab.medilink.com.ph/open-source-team/innerpeace_umbrella/commits/master)


# Innerpeace
This project is composed of PayorLink, AccountLink, and MemberLink applications.

## Migrating PayorLink DB

1. Run `docker-compose build ip-build`
2. Run `docker-compose run ip-build scripts/build/migrate.sh`

## Migrating PayorLink DB with Seed Data

1. Run `docker-compose build ip-build`
2. Run `docker-compose run ip-build scripts/build/migrate-with-seed.sh`

## Deploying Payorlink in Kubernetes

1. Bump version of payorlink image & mix.exs
- apps/payorlink/mix.exs
- docker-compose.yml
- scripts/k8/payorlink.yml
- .gitlab-ci.yml

2. Run `docker-compose build ip-build`
3. Run `docker-compose build payorlink`
4. Run `gcloud docker -- push asia.gcr.io/silver-approach-172802/payorlink:{version}`
5. Update the docker image version in scripts/k8/payorlink.yml
6. Run `kubectl apply -f scripts/k8/payorlink.yml`

## Manually deploying of Payorlink
1. Bump version in master branch (run :%s/[old version]/[new version] to update following files)
	- payorlink -> mix.exs
	- docker-compose.yml
	- scripts -> k8 -> payorlink.yml
	- :e .gitlab-ci.yml
2. Push changes to master
3. Create merge request (master -> staging)
4. Go to staging branch and update
5. cd apps/payor_link
6. Build
	- mix edeliver build release --branch=staging
7. Deploy to staging
	- mix edeliver deploy release to staging --version=[new version]
8. Go to staging server
	- ssh medi@172.16.241.53 (payorsuite)
	- sudo systemctl restart payorlink.service
	- key in default password
9. Go to master branch to migrate staging db
	- open config/dev.exs
	- comment uncomment the environment to be migrated
	- mix ecto.migrate
	- run seeds
	- Note: Do not commit changes
10. Deploy to uat
	- mix edeliver deploy release to uat --version=[new version]
11. Go to uat server
	- ssh medi@172.16.23.61
	- systemctl restart payorlink.service
	- key in default password
12. Go to master branch to migrate uat db
	- open config/dev.exs
	- comment uncomment the environment to be migrated
	- mix ecto.migrate
	- run seeds
	- Note: Do not commit changes

## Manually deploying of MemberLink
1. Bump version in master branch (run :%s/[old version]/[new version] to update following files)
	- memberlink -> mix.exs
2. Push changes to master
3. Create merge request (master -> staging)
4. Go to staging branch and update
5. cd apps/member_link
6. Build
	- mix edeliver build release --branch=staging
7. Deploy to staging
	- mix edeliver deploy release to staging --version=[new version]
8. Go to staging server
	- ssh medi@172.16.241.53 (payorsuite)
	- sudo systemctl restart memberlink.service
	- key in default password
9. Go to master branch to migrate staging db
	- open config/dev.exs
	- comment uncomment the environment to be migrated
	- mix ecto.migrate
	- run seeds
	- Note: Do not commit changes
10. Deploy to uat
	- mix edeliver deploy release to uat --version=[new version]
11. Go to uat server
	- ssh medi@172.16.23.61
	- systemctl restart memberlink.service
	- key in default password
12. Go to master branch to migrate uat db
	- open config/dev.exs
	- comment uncomment the environment to be migrated
	- mix ecto.migrate
	- run seeds
	- Note: Do not commit changes

## Manually deploying of AccountLink
1. Bump version in master branch (run :%s/[old version]/[new version] to update following files)
	- accountlink -> mix.exs
2. Push changes to master
3. Create merge request (master -> staging)
4. Go to staging branch and update
5. cd apps/account_link
6. Build
	- mix edeliver build release --branch=staging
7. Deploy to staging
	- mix edeliver deploy release to staging --version=[new version]
8. Go to staging server
	- ssh medi@172.16.241.53 (payorsuite)
	- sudo systemctl restart accountlink.service
	- key in default password
9. Go to master branch to migrate staging db
	- open config/dev.exs
	- comment uncomment the environment to be migrated
	- mix ecto.migrate
	- run seeds
	- Note: Do not commit changes
10. Deploy to uat
	- mix edeliver deploy release to uat --version=[new version]
11. Go to uat server
	- ssh medi@172.16.23.61
	- systemctl restart accountlink.service
	- key in default password
12. Go to master branch to migrate uat db
	- open config/dev.exs
	- comment uncomment the environment to be migrated
	- mix ecto.migrate
	- run seeds
	- Note: Do not commit changes

## Manually deploying of RegistrationLink
1. Bump version in master branch (run :%s/[old version]/[new version] to update following files)
	- registrationlink -> mix.exs
2. Push changes to master
3. Create merge request (master -> staging)
4. Go to staging branch and update
5. cd apps/registration_link
6. Build
	- mix edeliver build release --branch=staging
7. Deploy to staging
	- mix edeliver deploy release to staging --version=[new version]
8. Go to staging server
	- ssh medi@172.16.241.53 (payorsuite)
	- sudo systemctl restart registrationlink.service
	- key in default password
9. Go to master branch to migrate staging db
	- open config/dev.exs
	- comment uncomment the environment to be migrated
	- mix ecto.migrate
	- run seeds
	- Note: Do not commit changes
10. Deploy to uat
	- mix edeliver deploy release to uat --version=[new version]
11. Go to uat server
	- ssh medi@172.16.23.61
	- systemctl restart registrationlink.service
	- key in default password
12. Go to master branch to migrate uat db
	- open config/dev.exs
	- comment uncomment the environment to be migrated
	- mix ecto.migrate
	- run seeds
	- Note: Do not commit changes

## To test deployment

1. docker run -p 4001 --env-file .env asia.gcr.io/silver-approach-172802/payorlink:{version} _build/prod/rel/innerpeace/bin/innerpeace foreground
