# Amphisbaena

Amphisbaena is a library of simple objects that make it easy to manipulate XML contents in memory. Once an XML file is parsed into an Amphisbaena container, you can traverse, copy, delete, and move data as necessary to accomplish a variety of tasks. Once you are finished editing your container, it natively exports its contents to an XML file, already formatted for you.

The incarnation of Amphisbaena on this GitHub page is the version started in February 2020 for the [Wóoyake Project](https://wooyake.wordpress.com/), using the [Swift programming language](https://developer.apple.com/swift/). It is maintained for individuals working in that project who use Amphisbaena to unify multiple data sources into a single XML file. Later incarnations of Amphisbaena may be rewritten using languages that more easily allow for cross-platform support, such as Java or Python.

Amphisbaena may refer to either the app used by the Wóoyake Project, or the underlying libraries and classes used to support that app.

## Requirements

* Xcode. The current version of Amphisbaena was built in Xcode 11.5 using Swift 5, but may work on later versions.
* macOS Catalina 10.15.4 and later.

## Builds

The following build(s) are available for individuals who do not wish to build Amphisbaena themselves from Xcode. These are not likely to be the most up-to-date versions available, but will have the most stable features at the time they are provided. They are provided as-is.

The apps provided here may not be notarized and may need to bypass Gatekeeper to run properly. To do this, **Option-click/Right click the app > Open**, and click **Open** in the dialog that comes up.

* Amphisbaena 0.15: [Link](https://www.dropbox.com/s/fe33kp1qsqjwqcn/Amphisbaena%200-15.zip?raw=1) **New!**
* Amphisbaena 0.10: [Link](https://www.dropbox.com/s/tae3blqrsyk7mep/Amphisbaena%200-1.zip?raw=1)

## Documentation

Documentation of Amphisbaena is on the wiki here: https://github.com/SRSTLCI/amphisbaena/wiki

## Project

The .app built with this project uses subclasses of the basic Amphisbaena classes to accomplish goals relating to data formatting for the [Wóoyake Project](https://wooyake.wordpress.com/). As such, the app is purpose-built for these goals, and demonstrates some of what is possible with Amphisbaena classes. It has full `NSDocument` functionality, allowing a user to save and load full project files, rather than needing to import and re-import files continually across app sessions.

Parsers are written as classes that invoke an `XMLParser` from the Apple standard `Foundation` library, which then collect XML contents into subclasses of `Amphisbaena_Container` which have features specific to their use cases.

Sample files that we have used in the building of Amphisbaena are included in the _Sample Files_ folder at the project root. These are provided as-is and allow you to test the capabilities of the Amphisbaena app.

## Why "Amphisbaena?"

Amphisbaena was a project born of Mother Necessity. We needed a way to unify several disperate file types that had a commonality of being XML-based file types. Several solutions were considered, including a variety of data mapping software solutions. In time, it was discovered that these were unsuitable for our needs as we needed to make more granular decisions about how the data moves and is formatted for the goals of the Wóoyake Project.

As a result, Amphisbaena began as a project that acted as an umbrella name for several purpose-built programming scripts to unify data in the Wóoyake Project. Initial attempts at writing Amphisbaena scripts began in Python, and Amphisbaena itself was named as such for two major clever reasons:

* An _Amphisbaena_ is a double-ended serpent with a head at each end, to reflect the nature of these scripts' attempts to unify data types.
* A reference to Python, which is a name for our first choice of programming language as well as a reptillian animal in reference to the mythical creature.

When it became clear that maintaining and updating several different scripts to all build data for our changing needs, it was decided that Amphisbaena needed to be recreated from scratch as a more flexible format. The current incarnation of Amphisbaena was born, and now uses a single underlying library to build and modify XML files with programmer and user intent. The Amphisbaena app serves as a proof of concept for this technology, as well as a working example of how this work could benefit a project, such as our own Wóoyake Project.

More about Amphisbaena can be read here: [Link](https://wooyake.wordpress.com/2020/04/10/bringing-file-types-together/)

## License

To be determined.

For now, members of the Wóoyake Project may examine the code and make modifications to suit their workflow if necessary when building from the Xcode project, and use the resulting .app in their work.

Non-members of the Wóoyake Project may examine the code and make modifications to suit their personal needs. Please do not distribute any derivative software at this point in time. Pull requests are welcome. For major changes, please open an issue to discuss what you would like to change.

Contact us if you decide to use Amphisbaena in your own project. We would love to hear about it!

## Bug Reports and Feature Requests

Amphisbaena is very early in its lifetime and we appreciate the reporting of any bugs, for both the full app as well as the underlying classes. Please feel free to report any bugs you find at any time.

Please bear in mind that as of this writing, many aspects of Amphisbaena's UI are unfinished or vestigal. We may decide to address this more concretely in the future, but this may be determined as internal needs are considered.

If you think Amphisbaena requires a new feature, feel free to log a request in the Issue tracker.

