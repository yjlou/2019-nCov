# 2019-nCov
Use Google Maps Timeline data to check whether you had contacted the patient or not.

# The Web Interface

With a pre-loaded patient historical track data, user can drag/drop in their tracks to compare.

Note that all comparisons are happening in the local. Nothing is uploaded to server. This can
ensure the user's privacy is protected.

# NodeJs for Spacetime hash

To protect patient's privacy, we employ a simple hash algorithm called ST hash (SpaceTime hash)
to hash (time point, lat, lng) into a 64-bit value. Then, when user wants to compare their
historical track, they follow the same hash algorithm. If a conflict happens, it means the user
and the patient have had met at a particular spacetime point.

The following commands are used to generate the hashed JSON file.

```
  # Node.js v12.x:
  curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
  sudo apt-get install -y nodejs
  npm install js-sha256 fs yargs fast-xml-parser

  node nodejs/sthash.js
  node nodejs/sthash.js -d "your description" --remove_top 3
                        -i INPUT_FILE.{kml|json} -o OUTPUT_FILE-hashed.json
```

Once the hashed JSON is generated, host it in somewhere (remember to enable Allow- headers
so that it follows the CORS policy), and use hashes= parameter in the URL to load it:

```
  https://yjlou.github.io/2019-nCov/?hashes=YOUR_HASHED_FILE_URL
```


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

See production [here](https://yjlou.github.io/2019-nCov/). New change may take few minutes to be
propagated on the server side.
