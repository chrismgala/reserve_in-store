#!/bin/bash

say() {
  echo "> $1"
}

if [ "$1" == "" ]; then
  say 'Script to deploy our apps, please be careful.'
  say 'USAGE: ./deploy.sh ( all | events | workers | workers1 | workers2 | web )'
  echo ''
  exit 0
fi


if [[ ("$1" == 'all') || ("$1" == 'web') ]]; then

  say 'Deploying reserve_in-store to Heroku'

  echo "Notifying team that a new version is deploying..."
  curl -X POST --data-urlencode "payload={\"channel\": \"#reserve_in_store\", \"username\": \"reserveinstore-engineering\", \"text\": \":train: $(echo $USER) just started deploying latest master to Heroku...\", \"icon_emoji\": \":robot_face:\"}" https://hooks.slack.com/services/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


  if ! [ $(git remote | grep -x heroku) ]; then
    say 'Adding missing heroku remote'
    git remote add heroku https://git.heroku.com/reserve_in-store.git
  fi

  git push heroku master

  echo "Invalidating CDN on AWS CDN..."
  aws cloudfront create-invalidation --distribution-id E213IUVF8P25UK --paths "/*"


  echo "Invalidating CDN on CloudFront..."
  curl -X POST "https://api.cloudflare.com/client/v4/zones/eb1bc99afdb00154120a4f5c5f84260a/purge_cache" \
       -H "X-Auth-Email: jay@bananastand.io" \
       -H "X-Auth-Key: $PUBLIC_CDN_CLOUDFLARE_AUTH_KEY" \
       -H "Content-Type: application/json" \
       --data '{"purge_everything":true}'

  # Add the tag so we know where the assets are sitting
  git push --delete upstream public_cdn
  git tag --delete public_cdn
  git tag -a -m "Deployed to workers" public_cdn
  git push -v upstream refs/tags/public_cdn


  echo "Notifying team that a new version has been deployed..."
  curl -X POST --data-urlencode "payload={\"channel\": \"#reserve_in_store\", \"username\": \"reserveinstore-engineering\", \"text\": \":tropical_drink: $(echo $USER) finished deploying latest master to Heroku.\", \"icon_emoji\": \":robot_face:\"}" https://hooks.slack.com/services/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


  say "Pinging Zappier that a deploy occured..."
  curl --header "Content-Type: application/json" --request POST  --data '{"user":"'$(id -un)'"}' https://hooks.zapier.com/hooks/catch/4195891/cni7ld/


  say 'Done! 👍 '

fi


