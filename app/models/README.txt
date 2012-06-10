APPILEO DATA STRUCTURE FOR MONGO DB
===================================

In this project we are modeling the MongoDB models with MongoMapper (MM).
Using MM it is important to define the top level of the collection as Document
and any nested document as EmbeddedDocument. Although some of the "Dirty"
functionality of Active Records does not exists (changed, create, ...) the gain
is that the every nested document is saved directly and only into it's parent.

An additional benefit of using EmbeddedDocuments is that the assignments, that
is done by calling the new initializer method on the object class, are not saving
to the database immediately but explicit save has to be called on the root
document object model. using Documents classes for the nested objects, which we
do not do here, results in duplicate pointers in the database, both under the
parent object model and under the model collection itself, to the object and
complete removal of the object can occur only by calling destroy on all the
instances that are tied to it.

Nested objects can be easily created, by calling "= new" on "one" relationship
or "<< new" on many relationships, and deep nested queries can be called by
querying an object with :conditions as a key for a hash of nested conditions.


For example:

class A
	include MongoMapper::Document
	one :b
end

class B
	include MongoMapper::EmbeddedDocument
	one :c
end

class C
	include MongoMapper::EmbeddedDocument
	key :name, String, :require => true
end

a = A.create()
a.b = B.new
a.b.c = C.new
a.b.c.name = 'appileo'
a.save
A.all(:conditions => {'b.c.name' => 'appileo'})

