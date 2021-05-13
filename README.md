# 2019-nCov
Use Google Maps Timeline data to check whether you had contacted the patient or not.  

Check it now! [https://pandemic.events](https://pandemic.events)

# The Web Interface

## Patient Data from Trustable Sources

We integrate trustable data sources into our tool. With the patient historical track data, user
can drag/drop in their tracks to compare.  Please read 'countries' folder for more details.

Note that all comparisons are happening on the local device. Nothing is uploaded to server.
This can ensure the user's privacy is protected.

## Use Your Own Patient Data

This is useful when you want to use your own patient data, but without sharing it with rest of
the world.  By assigning a 'patient=URL' parameter in URL, you can load your own patient data.
The file can be either JSON or KML format.

A use case is that a trustable third party (e.g. a government CDC) reads out the history
location data from patient's phone, but they don't want to publish patient's data to make public
panic. Instead, they can host the patient data in URL and use 'patient=URL' to load it into this
tool. Then, they can compare people's history location data (the people can voluntarily provide
their own data to the trustable third party) in the step 3 of this tool (by dragging and dropping
tons of data files).

Same here.All comparisons are happening on local device. Nothing is uploaded to server.

# Contribution

## Testing

This project comes with unittest code. Please open the browser debug console and type:

```
  test();
```

Then you should be able to see the following message which indicates all test cases have passed.

```
  test.js:56 [PASS]
```

If you see any error, please fix them before you upload.


## Push to development page:

```
  $ git push origin master:master  # replace the first 'master' with your local branch name
```

See preview [here](http://raw.githack.com/yjlou/2019-nCov/master/index.html).
New change may take few minutes to be propagated on the server side.

Note that the preview is only for developer and could be broken anytime. If you are not developer,
please use the [production page](https://pandemic.events) instead.

## Push to production

Ensure your local repo is clean to create a branch.

```
  $ export ORG_BRANCH=$(git branch | grep \* | cut -d ' ' -f2)       # Save original branch name.
  $ git checkout -b prod origin/master                               # Checkout new branch. Change
                                                                     # 'origin/master' in case you
                                                                     # prefer something else.
  $ git push origin prod:gh-pages                                    # Push to production.
  $ git checkout ${ORG_BRANCH}                                       # Move back to original branch.
  $ git branch -D prod
```

See production [here](https://pandemic.events). New change may take few minutes to be
propagated on the server side.

## Local test
To start local server:
```
npm install  # or just npm install http-server
node_modules/http-server/bin/http-server .
```
