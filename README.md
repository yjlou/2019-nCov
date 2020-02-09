# 2019-nCov
Use Google Maps Timeline data


# Push to development page:

```
  $ git push origin master:master  # replace the first 'master' with your local branch name
```

See preview [here](http://htmlpreview.github.io/?https://github.com/yjlou/2019-nCov/blob/master/index.html).
New change may take few minutes to be propagated on the server side.

# Push to production

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
