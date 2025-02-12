# Architecture Overview

Owl is an emerging library developed in the OCaml language for scientific and engineering computing. It focuses on providing a comprehensive set of high-level numerical functions so that developers can quickly build up any data analytical applications. After over one-year intensive development and continuous optimisation, Owl has evolved into a powerful software system with competitive performance to mainstream numerical libraries.
Meanwhile, Owl’s overall architecture remains simple and elegant. Its small code base can be easily managed by a small group of developers.

In this chapter, we first present Owl's design, core components, and its key functionality. We show that Owl benefits greatly from OCaml's module system which not only allows us to write concise generic code with superior performance, but also leads to a very unique design to enable parallel and distributed computing.
OCaml's static type checking significantly reduces potential bugs and accelerates the development cycle.
We also share the knowledge and lessons learnt from building up a full-fledge system for scientific computing with the functional programming community.

## Introduction

Thanks to the recent advances in machine learning and deep neural networks, there is a huge demand on
various numerical tools and libraries in order to facilitate both academic researchers and industrial developers to fast prototype and test their new ideas, then develop and deploy analytical applications at large scale.
Take deep neural network as an example, Google invests heavily in TensorFlow while Facebook promotes their PyTorch.
Beyond these libraries focusing on one specific numerical task, the interest on general purpose tools like Python and Julia also grows fast.
Python has been one popular choice among developers for fast prototyping analytical applications.
One important reason is because SciPy and NumPy two libraries, tightly integrated with other advanced functionality such as plotting, offer a powerful environment which lets developers write very concise code to finish complicated numerical tasks. As a result, even for the frameworks which were not originally developed in Python (such as Caffe and TensorFlow), they often provide Python bindings to take advantage of the existing numerical infrastructure in NumPy and SciPy.

On the other hand, the supporting of basic scientific computing in OCaml is rather fragmented. There have been some initial efforts (e.g., Lacaml, Oml, Pareto, etc.), but their APIs are either too low-level to offer satisfying productivity, or the designs overly focus on a specific problem domain. Moreover, inconsistent data representation and careless use of abstract types make it difficult to pass data across different libraries.
Consequently, developers often have to write a significant amount of boilerplate code just to finish rather trivial numerical tasks.
As we can see, there is a severe lack of a general purpose numerical library in OCaml ecosystem. We believe OCaml per se is a good candidate for developing such a general purpose numerical library for two important reasons: 1) we can write functional code as concise as that in Python with type-safety; 2) OCaml code often has much superior performance comparing to dynamic languages such as Python and Julia.

However, designing and developing a full-fledged numerical library is a non-trivial task, despite that OCaml has been widely used in system programming such as MirageOS.
The key difference between the two is obvious and interesting: system libraries provide a lean set of APIs to abstract complex and heterogeneous physical hardware, whilst numerical library offer a fat set of functions over a small set of abstract number types.

When Owl project started in 2016, we were immediately confronted by a series of fundamental questions like: "what should be the basic data types", "what should be the core data structures", "what modules should be designed", etc.
In the following development and performance optimisation, we also tackled many research and engineering challenges on a wide range of different topics such as software engineering, language design, system and network programming, etc.

In this chapter, We show that Owl benefits greatly from OCaml’s module system which not only allows us to write concise generic code with superior performance, but also leads to a very unique design to enable parallel and distributed computing.
OCaml's static type checking significantly reduces potential bugs and accelerate the development cycle. We would like to share the knowledge and lessons learnt from building up a full-fledge system for scientific computing with the functional programming community.

## Architecture Overview

Owl is a complex library consisting of numerous functions (over 6500 by the end of 2017), we have strived for a modular design to make sure that the system is flexible enough to be extended in future. In the following, we will present its architecture briefly.

![Owl system architecture](images/architecture/owl-architecture.png "owl-architecture"){width=95% #fig:architecture:architecture}

The [@fig:architecture:architecture] gives a bird view of Owl’s system architecture, i.e. the two subsystems and their modules.
The subsystem on the left part is Owl's Numerical Subsystem. The modules contained in this subsystem fall into three categories:
(1) core modules contains basic data structures and foreign function interfaces to other libraries (e.g., CBLAS and LAPACKE);
(2) classic analytics contains basic mathematical and statistical functions, linear algebra, regression, optimisation, plotting, etc.;
(3) composable service includes more advanced numerical techniques such as deep neural network, natural language processing, data processing and service deployment tools.

The numerical subsystem is further organised in a
stack of smaller libraries, as follows.

- **Base** is the basis of all other libraries in Owl. Base defines core data structures, exceptions, and part of numerical functions.
Because it contains pure OCaml code so the applications built atop of Base can be safely compiled into native code,
bytecode, JavaScript, even into unikernels.
Fortunately, majority of Owl’s advanced functions are implemented in pure OCaml.

- **Owl** is the backbone of the numerical subsystem. It depends on Base but replaces some pure OCaml functions with C implementations (e.g. vectorised math functions in Ndarray module).
Mixing C code into the library limits the choice of backends (e.g. browsers and MirageOS) but gives us significant performance improvement when running applications on CPU.

- **Zoo** is designed for packaging and sharing code snippets among users. This module targets small scripts and light numerical functions which may not be suitable for publishing on the heavier OPAM system. The code is distributed via gists on Github, and Zoo is able to resolve the dependency and automatically pull in and cache the code.

- **Top** is the Toplevel system of Owl. It automatically loads both Owl and Zoo, and installs multiple pretty printers for various data types.

The subsystem on the right is called Actor Subsystem which extends Owl's capability to parallel and distributed computing. The addition of Actor subsystem makes Owl fundamentally different from mainstream numerical libraries such as SciPy and Julia.
The core idea is to transform a user application from sequential execution mode into parallel mode (using various computation engines) with minimal efforts.
The method we used is to compose two subsystems together with functors to generate the parallel version of the module defined in the numerical subsystem.

Besides, there are other utility modules such as plotting.
Plotting is an indispensable function in modern numerical libraries. We build Plot module on top of PLplot which is a powerful cross-platform plotting library.
However PLPlot only provides very low-level functions to interact with its multiple plotting engines, even making a simple plot involves very lengthy and tedious control sequence.
Using these low-level functions directly requires developers to understand the mechanisms in depth, which not only significantly reduces the productivity but also is prone to errors.
Inspired by Matlab, we implement Plot module to provide developers a set of high-level APIs. The core plotting engine is very lightweight and only contains
about 200 LOC.
Its core design is to cache all the plotting operations as a sequence of function closures and execute them all when we output the figure.

## Core Implementation

### N-dimensional Array

N-dimensional array and matrix are the building blocks
of Owl library, their functionality are implemented in
Ndarray and Matrix modules respectively. Matrix is
a special case of n-dimensional array, and in fact many
functions in Matrix module call the corresponding functions in Ndarray directly.

For n-dimensional array and matrix, Owl supports
both dense and sparse data structures. The dense data
structure is built atop of OCaml’s native Bigarray module hence it can be easily interfaced with other libraries
like BLAS and LAPACK. Owl also supports both single and double precisions for both real and complex number. Therefore, Owl essentially has covered all the necessary number types in most common scientific computations.

- The first group contains the vectorised mathematical functions such as sin, cos, relu, etc.

- The second group contains the high-level functionality to manipulate arrays and matrices, e.g., index, slice, tile, repeat, pad, etc.

- The third group contains the linear algebra functions specifically for matrices. Almost all the linear algebra functions in Owl call directly the corresponding functions in CBLAS and LAPACKE.

These functions together provide a strong support for developing high-level numerical functions. Especially the first two groups turn out to be extremely useful for writing machine learning and deep neural network applications.
Function polymorphism is achieved using GADT (Generalized algebraic data type), therefore most functions in Generic
module accept the input of four basic number types.

**Optimisation with C Code**

Interfacing to high performance language is not uncommon practice among numerical libraries. If you look at the source code of NumPy, more than 50% is C code. In SciPy, the FORTRAN and C code takes up more than 40%. Even in Julia, about 26% of its code is in C or C++, most of them in the core source code.

Besides interfacing to existing libraries, we focus on implementing the core operations in the Ndarray modules with C code. As we have seen in the N-Dimensional Arrays chapter, the n-dimensional array module lies in the heart of Owl, and many other libraries. NumPy library itself focuses solely on providing a powerful ndarray module to the Python world.

An ndarray is a container of items of the same type. It consists of a contiguous block of memory, combined with an indexing scheme that maps N integers into the location of an item in the block. A stride indexing scheme can then be applied on this block of memory to access elements. Once converted properly to the C world, a ndarray can be effectively manipulated with normal C code.

There is a big room for optimising the C code. We are trying to push the performance forward with multiple techniques. We mainly use the multiprocessing with OpenMP and parallel computing using SIMD intrinsics when possible.

### Interfaced Libraries

Some functionality such as math and linear algebra is included into the system by interfacing to other libraries. Rather than simply exposing the low-level functions, we carefully design easy-to-use high-level APIs
and this section will cover these modules.
For example, the mathematical functions, especially the special functions, are interfaced from the Cephes Mathematical Functions Library, and the normal math functions rely on the standard C library.


Even though Fortran is no longer among the top choices as a programming language, there is still a large body of FORTRAN numerical libraries whose performance still remain competitive even by today’s standard, e.g. BLAS and LAPACK.
When designing the linear algebra module, we decide to interface to CBLAS and LAPACKE (i.e. the corresponding C interface of BLAS and LAPACK) then further build higher-level APIs atop of the low-level FORTRAN functions.
The high-level APIs hides many tedious tasks such as setting memory layout, allocating workspace, calculating strides, etc.

## Advanced Functionality

Built on these core modules are the advanced functionalities in Owl. We have introduced many of them in the first part of this book.

### Computation Graph

As a functional programmer, it is basic knowledge that a function takes an input then produces an output. The input of a function can be the output of another function which then creates dependency. If we view a function as one node in a graph, and its input and output as incoming and outgoing links respectively, as the computation continues, these functions are chained together to form a directed acyclic graph (DAG). Such a DAG is often referred to as a computation graph.

Computation graph plays a critical role in our system.
Its benefits are many-fold: provides simulate lazy evaluation in a language with eager evaluation, reduce computation complexity by optimising the structure of a graph, reduce memory footprint, etc.
It can be used for supporting multiple other high level modules e.g. algorithmic differentiation, and GPU computing modules all implicitly or explicitly use computation graph to perform calculations.

### Algorithmic Differentiation

Atop of the core components, we have developed several modules to extend Owl’s numerical capability. E.g.,
Maths module includes many basic and advanced mathematical functions, whist `Stats` module provides various statistical functions such as random number generators, hypothesis tests, and so on. The most important extended module is Algodiff, which implements the algorithmic differentiation functionality.
Owl's Algodiff module is based on the core nested automatic differentiation algorithm and differentiation API of DiffSharp, which provides support for both forward and reverse differentiation and arbitrary higher order derivatives.

Algodiff module is able to provide the derivative, Jacobian, and Hessian of a large range of functions, we exploit this power to further build the optimisation engine.
The optimisation engine is light and highly configurable, and also serves as the foundation of Regression module and Neural Network module because both are essentially mathematical optimisation problems.
The flexibility in optimisation engine leads to an extremely compact design and small code base. For a full-fledge deep neural network module, we only use about 2500 LoC and its inference performance on CPU is superior to specialised frameworks such as TenserFlow
and Caffee.

### Regression

Regression is an important topic in statistical modelling and machine learning. It's about modelling problems which include one or more variables (also called "features" or "predictors") and making predictions of another variable (“output variable”) based on previous data of predictors.

Regression analysis includes a wide range of models, from linear regression to isotonic regression, each with different theory background and application fields. Explaining all these models are beyond the scope of this book. In this chapter, we focus on several common forms of regressions, mainly linear regression and logistic regression. We introduce their basic ideas, how they are supported in Owl, and how to use them to solve problems.

### Neural Network

We have no intention to make yet another framework for deep neural networks. The original motivation of including such a neural network module was simply for demo purpose.
It turns out that with Owl's architecture and its internal functionality (Algodiff, CGraph, etc.), combined with OCaml's powerful module system, implementing a full featured neural network module only requires approximately 3500 LoC.

Algodiff is the most powerful part of Owl and offers great benefits to the modules built atop of it. In neural network case, we only need to describe the logic of the forward pass without worrying about the backward propagation at all, because the Algodiff figures it out automatically for us thus reduces the potential errors. This explains why a full-featured neural network module only requires less than 3.5k LoC. Actually, if you are really interested, you can have a look at Owl's Feedforward Network which only uses a couple of hundreds lines of code to implement a complete Feedforward network.

## Parallel Computing

### Actor Engine

Parallelism can take place at various levels, e.g. on
multiple cores of the same CPU, or on multiple CPUs
in a network, or even on a cluster of GPUs. OCaml
official release only supports single threading model at
the moment, and the work on Multicore OCaml is
still ongoing in the Computer Lab in Cambridge. In the
following, we will present how parallelism is achieved in
Owl to speed up numerical computations.

The design of distributed and parallel computing module essentially differentiates Owl from other mainstream
numerical libraries. For most libraries, the capability
of distributed and parallel computing is often implemented as a third-party library, and the users have to
deal with low-level message passing interfaces. However, Owl achieves such capability through its Actor
subsystem.

### GPU Computing

Scientific computing involves intensive computations,
and GPU has become an important option to accelerate
these computations by performing parallel computation
on its massive cores. There are two popular options in
GPGPU computing: CUDA and OpenCL. CUDA is
developed by Nvidia and specifically targets their own
hardware platform whereas OpenCL is a cross platform
solution and supported by multiple vendors. Owl currently supports OpenCL and CUDA support is included
in our future plan.

To improve performance of a numerical library such as Owl, it is necessary to support multiple hardware platforms. One idea is to "freeride" existing libraries that already support various hardware platforms. We believe that computation graph is a suitable IR to achieve interoperability between different libraries. Along this line, we develop a prototype symbolic layer system by using which the users can define a computation in Owl and then turn in into ONNX structure, which can be executed with many different platforms such as TensorFlow.
By using the symbolic layer, we show the system workflow, and how powerful features of Owl, such as algorithmic differentiation, can be used in TensorFlow. We then briefly introduce system design and implementation.

### OpenMP

OpenMP uses shared memory multi-threading model
to provide parallel computation. It is requires both
compiler support and linking to specific system libraries.
OpenMP support is transparent to programmers. It can
be enabled by turning on the corresponding compilation
switch in `dune` file.
After enabling OpenMP, many vectorised math operators are replaced with the corresponding OpenMP implementation in the compiling phase.
However, parallelism offered by OpenMP is not a free lunch. The scheduling
mechanism adds extra overhead to a computation task.
If the task per se is not computation heavy or the ndarray is small, OpenMP often slows down the computation. We therefore set a threshold on ndarray size below which OpenMP code is not triggered. This simple mechanism turns out to be very effective in practice.
To further utilise the power of OpenMP, we build an automatic tuning module to decide the proper threshold value for different operations.

## Community-Driven R&D

After three years of intense development, Owl currently contains about 130k lines of OCaml code and 100k lines of C code.
As of March 2020, it contains about 4,200 commits and contains 29 releases.
Owl has a small and concise team. These codes are mainly provided by three main developers, but so far more than 40 contributors have also participated in the project.

Owl is a large open source project, to guarantee quality of the software and sustainable development. We enforce the following rules in day-to-day research, development, and project management.
Besides coding, there are many other ways you can contribute. Bug reporting, typo fix, asking/answering questions, and improvement of existing documents are all well welcome.

**Coding Style**

Coding style guarantees a consistent taste of code written by different people. It improves code readability and maintainability in large software projects.
OCaml is the main developing language in Owl. We use [ocamlformat](https://github.com/ocaml-ppx/ocamlformat) to enforce the style of OCaml code.
There is also a significant amount of C code in the project. For the C code, we apply the [Linux kernel coding style](https://www.kernel.org/doc/html/v4.10/process/coding-style.html).
The coding style does not apply to the vendor's code directly imported into Owl source code tree.

**Unit Test**

All the code must be well tested before submitting a pull request.
If existing functions are modified, you need to run the unit tests to make sure the changes do not break any tests.
If existing functions are modified, you may also need to add more unit tests for various edge cases which are not covered before.
If new functions are added, you must add corresponding unit tests and make sure edge cases are well covered.

**Pull Request**

Minor improvement changes can be submitted directly in a pull request. The title and description of the pull request shall clearly describe the purpose of the PR, potential issues and caveats.
For significant changes, please first submit a proposal on Owl's issue tracker to initialise the discussion with Owl Team.
For sub libraries building atop of Owl, if you want the library to be included in the "owlbarn" organisation, please also submit the proposal on issue tracker. Note that the license of the library must be compliant with "owlbarn", i.e. MIT or BSD compliant. Exception is possible but must be discussed with Owl Team first.
Pull requests must be reviewed and approved by at least two key developers in Owl Team. A designated person in Owl Team will be responsible for assigning reviewers, tagging a pull request, and final merging to the master branch.

**Documentation**

For inline documentation in the code, the following rules apply.

- Be concise, simple, and correct.
- Make sure the grammar is correct.
- Refer to the original paper whenever possible.
- Use both long documentation in mli and short inline documentation in code.

For serious technical writing, please contribute to Owl's [tutorial book](https://github.com/owlbarn/book).

- Fixing typos, grammar issues, broken links, and improving tutorial tooling are considered as minor changes. You can submit pull requests directly to Tutorial Book repository.
- Extending existing chapters are medium changes and you need to submit a proposal to tutorial book issue tracker.
- Contributing a standalone chapter also requires submitting a chapter proposal. Alternatively, you can write to us directly to discuss about the chapter.


## Summary

As the first chapter in Part II, this chapter gives a brief overview of the Owl architecture, including the core modules, the advanced functionalities, and parallel computation support.
Some of these topics are covered in Part I, and we will talk about the rest in the second part of this book.
This part is about Owl's internal working mechanism.
Stay tuned if you are interested in how a numerical library is built, not just how it is used. 
