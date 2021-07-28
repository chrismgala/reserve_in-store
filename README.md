### Table of Contents

1. [Introduction](#introduction)
2. [Setup](#setup)
3. [Technology Overview](#technology-overview)
4. [Contributing](#contributing)
5. [Development Process](#development-process)
6. [Troubleshooting](#troubleshooting)


----


# Introduction
This repository is for the In-Store Reserver Shopify app.


## Application Overview

#### Why do merchants need this?
When customers comes in to your online store, they either make the purchases right away or they leaves. Especially when it comes to high-priced items, many people won't place their orders online. Let customers actually see the products will clearly increase their chance of buying. In-Store Reserver is a simple application that adds a "reserve in store" option in your online store. By adding this feature, you will have the chance to make more deals when customers comes into your store in person.

#### How do merchants start using the app?
** TODO: PLEASE FILL THIS OUT **

----

# Setup
Here's how to get the app running on your local computer for development.

### Prerequisites
You must have the following to run this app:
1. Postgres 9.6.8
2. Redis
3. Ruby 2.6.7


### Dev tools
* Bundler is used
* For JS/CSS assets we use [yarn](https://yarnpkg.com/lang/en/).
* To view emails being send installed [mailcatcher](https://mailcatcher.me)


### Installation
Follow these instructions to setup your local development environment:

1. Create a DB in postgres called `reserve_in-store` and the appropriate user permissions, OR run `rake db:create`
2. Copy .env-example to .env and fill in the relevant details. Assuming default settings from postgres and redis, then you'll probably not have to set anything up.
3. Run `bundle install && bundle exec rake db:migrate && bundle exec rake db:seed && yarn`. Then run `rails server` to run your rails server. All of these chained commands must pass for successful installation.

By default it runs at http://localhost:3000. You can also run the server through RubyMine so you can use the debugger and step through code.

You'll want to run this on another port other than 3000, so you don't conflict with other servers that are running. To do that you can run `rails server -p 3003` for example to run the rails server on port 3003.

If everything ran properly you should be able to see a standard Rails Getting Started when you got to http://localhost:3003 (or whatever your port is) in your browser.

## Setup the Platform API (Shopify, BigCommerce, etc)
If you want to test installing In-Store Reserver App store you will need to create a development app in Shopify (or BigCommerce or whatever platform you're working in). Here's how to do it:

#### 1. Setup ngrok.io
Signup at `ngrok.io` and/or install the app into your computer. Then just run it with `ngrok http 3000` if your port number is `3000` for your rails app. The default port for rails apps is `3000`. 
After setting this up you should be able to access your rails app from `https://**whatever**.ngrok.io`. Note you're ngrok URL for the next step.

Update your `.env` file with your ngrok URLs. For example if your ngrok URL was `reserve_in-store.ngrok.io` then you should have this in your `.env`:
```
BASE_APP_URL="https://reserve_in-store.ngrok.io"
```

#### 2. Create Draft/Private App
To do this for Shopify simply go to your partner dashboard and create a new private (or draft) app. The same thing applies for BigCommerce.

Here's what the setup looks like for Shopify after you're done setting up your draft app: ![](<img src="https://monosnap.com/image/fXPIUvzfILzDza1JGYzgLZVJgJXjNx.png">)

Replace the ngrok URLs you see in the screenshot with your own ngrok domains (IE instead of `reserveinstore.ngrok.io` use your own ngrok domain)

#### 3. Update your `.env` file
Update the following values in your `.env` file then restart your rails server:
```
SHOPIFY_API_KEY=""
SHOPIFY_API_SECRET=""
```

## Create a test store
Use the Shopify partner dashboard to make a Shopify development store.

## Install the app on your test store
After you've created your test store, navigate to your local web app (via your ngrok url) and enter in your URL to signup/Login and it should redirect you to the shopify page to authorize the dev app you created in the previous step.

** TODO: YOU WILL NEED TO MAKE THE APP WORK WITH OAUTH FIRST BEFORE BEING ABLE TO TEST AN INSTALL OF THE APP ON YOUR STORE **



----



# Technology Overview
#### Tech used:
Make sure you read up on and understand these technologies before diving into the application:
* Yarn
* Bootstrap
* jQuery
* Rails 4.1.8
* Redis for sessions
* Postgres
* Sidekiq
* Heroku

#### Major Ruby Gems Used
Make sure you read up on and understand these major gems before diving into the application:
* Kaminari for pagination - https://github.com/kaminari/kaminari
* Local Time for relative times - https://github.com/basecamp/local_time

#### Other notable things
* We are using Puma for our webserver and full advantage of Threading
* We are using SendGrid in production (using SMTP) to send emails (in production only).

#### Overview of the models
** TODO: FILL THIS OUT PLEASE. THIS SHOULD CONTAIN THE DETAILS OF YOUR TECH DESIGN**


-------


# Contributing

### How to contribute
To contribute to the repository:

1. Fork the repository.
2. Clone the forked repository locally.
3. Create a branch descriptive of your work. For example "my_new_feature_xyz".
4. When you're done work, push up that branch to **your own forked repository** (not the feracommerce/reserve_in-store one).
5. Visit https://github.com/feracommerce/reserve_in-store and you'll see an option to create a pull request from your forked branch to the master. Create a pull request.
6. Fill out the pull request template with everything it asks for and assign the pull request to someone to review.
7. Set the reviewee as yourself and the requested reviewer as whomever you want to review your PR.
8. Once the PR merges into master then it is ready for production and should be treated as such. It will be deployed to staging within minutes.


Henceforth the root master repo (`reserve_in-storeio/reserve_in-store`) will be referred to as `upstream` and your own fork will be referred to as `origin`.

### When to push to upstream
We only push branches to upstream if you:
1. Want to let other developers test and run the code, or
2. You want to work with other developers on some code that needs to be branched from master.

For example if you're working on `some_large_feature_x` you could create the branch, push to `upstream/some_large_feature_x` and then developer A and developer B can both submit PRs against `upstream/some_large_feature_x`.
Then when that feature is ready for merge into master, you just submit a single PR from `upstream/some_large_feature_x` to `upstream/master`

### Getting your PR approved
A few key things to note:
* PRs must pass the test suite before they can be merged (using Side CI). It will tell you in the Pull Request whether it is OK to merge yet.
* PRs must be approved by at least one requested reviewers before you can merge.
* After you implement changes requested from a reviewer then post back with a :recycle: to say something like `:recyle: Ready for you to look again at it please.`. **Note:** If you do not do this then you PR may not ever get re-reviewed after comments are taken into acocunt.
* If a PR comment starts with a :beer: `:beer:` then it is just a suggestion and preference of the reviewer and the comment is NON-blocking. That is, your PR may still be approved with these comments.
* If a PR comment starts with a :tipping_hand_man: `:tipping_hand_man:` then it is just informative and requires no action. It's like a "FYI"
* All other PR comments probably need to be addressed unless otherwise agreed by the reviewer.
* After a PR has been approved then you are free to merge.
* For contractors, your PR must be approved and merged before you may bill for your work on that component.
* PR reviews will happen ASAP but generally within 24 hours.

### Design Guide

#### Use our theme whenever possible.
Please use the theme to find user interface controls and the appropriate color palette.  Documentation can be found [here](https://angle-on-rails.herokuapp.com/dashboard/dashboard_v1). 

#### Be responsive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
Our app is used via mobile phone, tablet and Desktop.  Every view should be responsive.  Leverage Bootstrap to do this. 

In the frontend for customers and visitors (customers of our merchants) everything MUST Be mobile responsive and work perfectly in mobile views 300px wide and up.

In the app dashboard (where merchants log in to manage their In-Store Reserver App account) you don't have to support mobile views 100%, but it is highly recommended.

#### Use Bootstrap
It's important to understand Bootstrap's column layout in order to be effective with it.

```html
<!-- all columns must be proceeded by a div.row -->
<div class="row">
	<!-- this will create a column that is 100% wide on small screens (12/12),
	and 50% (6/12) wide on anything bigger than small -->
	<div class="col-sm-12 col-md-6">
	</div>
</div>
```

#### Indentation
Use four spaces for CSS and SCSS. 2 for Ruby code and HTML.

#### Adhere to best practices
Understand [CSS specificity](https://developer.mozilla.org/en-US/docs/Web/CSS/Specificity).  Only use an id selector when absolutely necessary, such as to namespace.  NEVER use `!important`.

## Ruby/Rails Style Guide
Use two spaces for Ruby and HTML. Follow the Ruby Style Guide: https://github.com/bbatsov/ruby-style-guide

#### Rdoc style
We use a modified version of rdoc for our code documentation. Here's how it looks:

```ruby
##
# This class tells you if a user's name is long.
# @see http://www.example.com
class LongNameChecker
  
  ##
  # @param [User] user The user who's name we want to check
  def initialize(user)
    @user = user
  end
  
  ##
  # Tells you if the name is too long.
  # @return [Boolean] True if the name is longer than 30 chars, false otherwise.
  def long?
    user_name.size > 30
  end
  
  private
  
  def user_name
    @user.try(:name).to_s
  end
  
  ##
  # Does something that is not 100% obvious from the name of the method
  def some_complicated_method
    # something complicated
  end
  
  ##
  # This method returns a collection of Store objects so you can see how to comment it
  # If it were just an array of Store models you'd put `[Array<Store>]`
  # @return [ActiveRecord::Collection<Store>]
  def user_stores
    account.stores
  end
```

Generally you should add comment blocks to every public method and any private methods that you are not totally obvious by their name. If a public method is 100% obvious and quite short, then you don't have to add a comment for it as well.

#### Adhere to convention over configuration.
Always use `link_to` and `image_tag`. Use `action\_model\_paths` wherever possible.

#### Be RESTful wherever possible, using Rails resources patterns
Stick to the PUT/PATCH/POST/GET patterns that Rails facilitates. This will help in scaling our app as we integrate with 3rd parties and become more of a SaaS platform.

#### Ruby Best Practices
* When adding to the Gemfile, make sure to alphabetize gems you add and set a specific version number of the gem (so that we don't get random versions loaded in production that aren't tested). Also mention a quick comment about **why** the gem is being included. This helps us clean up old unused gems in the future.
* When adding to the `package.json` file make sure to alphabetize your requirements and be as specific about the version number as you can for the same reason as above.
* Document methods unless it is 100% totally obvious what the method does. 95% of the time when you have parameters required you probably need a method doc block.


## JavaScript Style Guide
We use an object-oriented approach to JavaScript (as object-oriented as we can).

Use four spaces for JavaScript. Use the following style guide: https://github.com/airbnb/javascript

Use [JSDoc](http://usejsdoc.org/about-getting-started.html) to document methods inside JavaScript classes.

## CSS Style Guide
Use four spaces for CSS and SCSS. 

Follow the following style guide: https://github.com/airbnb/css


## General Coding Best Practices
* If you're going to leave commented code in the repository add a comment to the top (or somewhere) near the commented code explaining why you left it there. Most of the time, it doens't need to be there and we can find it later if we need it in our source control system
* Whenever something isn't 100% obvious, add code comments.
* Be consistent. When given the choice between being consistent and being slightly better, choose to be consistent. If you want to be better then make everything consistently better.
* **Make sure your IDE is configured to use spaces instead of tabs**
* **Make sure your IDE is configured to include a new line at the end of every file. In Sublime this is done by adding `"ensure_newline_at_eof_on_save": true` to your config.**


----


# Development Process

The following is the lifecycle of a task in our company. We follow a KanBan flow.
1. **Triage** - When a new task is created it is put in this status. This means that it is recognized and recorded, but has not yet been planned for development. Tasks in Triage should not be attempted by a developer yet. Tasks in this status board are always prioritized in order of importance - the top tasks are the most urgent and the bottom ones are least urgent.
2. **Planned** - Once we've specified all information needed to complete the task it goes in this category.
3. **Scheduled** - A planned task that is now going to be worked on this month or next month goes here. Developers still won't pick up tasks in this category, but can start looking at them to get a sense of what's coming up next month (or if the current Backlog is empty, you can take tasks from here)
4. **Backlog** - This means that the task has been approved for development and can be picked up by a developer. It may also be assigned to a developer at this stage. Tasks in this status are also prioritized - top as most urgent and bottom as least urgent. If you don't have any task currently in progress you should take the top task in the backlog that is not assigned or assigned to you.
5. **In Progress** - As soon as you start working on a task, even if you're just planning or gathering requirements, you should set the task to In Progress.
6. **In Review** - Once your task is complete and you put up a Pull Request for it then it goes in this status. If your work does not require a pull request, then you can also use this status to verify that you met all the requirements of the task.
7. **Merged** - Once your PR merges into our master branch it goes in this category. It will go out with the next release of the app.
8. **Deployed** - The task has hit production and can now be closed. Periodically we will hide the Released status tasks. Every month we clear this list out and review what was completed for the previous month.



----


# Troubleshooting


### Heroku's 30-second request limitation
Keep in mind that Heroku has a 30-second request limit. That means that if your controller request takes longer
than 30 seconds at any time then it will cause Heroku to show an error to the user. For tasks that generally
have the possibility of taking longer than 10 seconds you should running the task in the background as a 
worker and monitor the result asynchronously (with ajax or whatever).

### Windows Troubleshooting

1. Bluecloth 2.2.0 gem
ERROR: Failed to build gem native extension.
Follow this article (https://stackoverflow.com/questions/23970283/cant-install-bluecloth-2-2-0-gem-in-windows-7)

2. Sys-proctable gem
Error:rake aborted!
LoadError: Please add `sys-proctable` to your Gemfile for windows machines
cannot load such file -- sys/proctable

Add this code in gem file
gem "sys-proctable", '~> 1.1.5'

3. Mechanize gem
Error: Install the mechanize gem version ~>2.7.5 for using mechanize functions.

Add this code in gem file
gem "mechanize", '~> 2.7.5'

4. Bcrypt_ext
Error: cannot load such file -- 2.3/bcrypt_ext
Follow this article (https://github.com/codahale/bcrypt-ruby/issues/142)

Remove bcrypt (3.1.11-x64-mingw32) and bcrypt (3.1.11-x86-mingw32) in Gemfile.lock
