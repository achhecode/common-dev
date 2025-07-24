
## Configuration to run the spring boot project:


<img alt="" src="Media/Images/IntelliJ-Custom-Configuration-1.png" />


Edit Configurations...

<img alt="" src="Media/Images/IntelliJ-Custom-Configuration-2.png" />

Click **+** icon on top left

<img alt="" src="Media/Images/IntelliJ-Custom-Configuration-3.png" />


Application

<img alt="" src="Media/Images/IntelliJ-Custom-Configuration-4.png" />

Give any name and select the main class, the file where @SpringBootApplication is written.

Apply > Ok or Just ok

<img alt="" src="Media/Images/IntelliJ-Custom-Configuration-5.png" />

Now run directly from Run-Service. Just click play icon when Run-Service is selected.


## Add maven clean install skiptests as well


<img alt="" src="Media/Images/IntelliJ-Custom-Configuration-6.png" />

Select + > Maven

<img alt="" src="Media/Images/IntelliJ-Custom-Configuration-7.png" />


Give any name, select **clean install** in Run options, optionally add **Skip Tests** if you want to skip tests. Apply and Ok or just Ok.

<img alt="" src="Media/Images/IntelliJ-Custom-Configuration-8.png" />

Now do maven clean install using single click. Similar can be achieved using maven options.

maven > service-name > lifecycle > clean install skiptest(notice the icon selected)

<img alt="" src="Media/Images/IntelliJ-Custom-Configuration-9.png" />


---
