# DB handler functions

This image allows using generic commands to handle different databases format.

Currently it manages :

* Postgresql
* MySQL

The different actions available at the moment are :

* Create user and its associated db
* Remove user
* Dump database
* Restore databse

## Environment

## Usage

Wrap methods to communicate with database based on subscripts

## Caveats

Psql version to match the server for dumping

In Azure connection, the connection user shall be followed by a `@...` but this form **shall not** be present during user creation / removal.
