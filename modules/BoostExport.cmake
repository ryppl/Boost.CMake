##########################################################################
# Copyright (C) 2011 Daniel Pfeifer <daniel@pfeifer-mail.de>             #
#                                                                        #
# Distributed under the Boost Software License, Version 1.0.             #
# See accompanying file LICENSE_1_0.txt or copy at                       #
#   http://www.boost.org/LICENSE_1_0.txt                                 #
##########################################################################

include(CMakeParseArguments)
include("${Boost_DIR}/BoostCatalog.cmake")

set(_boost_cmake_templates_dir "${CMAKE_CURRENT_LIST_DIR}/templates")

# Export of Boost projects
function(boost_export)
  set(parameters
    BOOST_DEPENDS
    CODE
    DEFINITIONS
    DEPENDS
    INCLUDE_DIRECTORIES
    TARGETS
    )
  cmake_parse_arguments(EXPORT "" "VERSION" "${parameters}" ${ARGN})

  set(_find_package )
  set(_definitions  ${EXPORT_DEFINITIONS})
  set(_include_dirs )
  set(_libraries    )
  
  # should we really do this?
  if(EXPORT_INCLUDE_DIRECTORIES)
    include_directories(${EXPORT_INCLUDE_DIRECTORIES})
  endif(EXPORT_INCLUDE_DIRECTORIES)

  # Boost specific target name expansion...
  set(targets)
  foreach(target ${EXPORT_TARGETS})
    if(TARGET ${target})
      list(APPEND targets ${target})
    else()
      if(TARGET ${target}-shared)
        list(APPEND targets ${target}-shared)
      endif()
      if(TARGET ${target}-static)
        list(APPEND targets ${target}-static)
      endif()
    endif()
  endforeach(target)
  set(EXPORT_TARGETS ${targets})
  unset(targets)
  # EXPORT_TARGETS now contains the real list of targets

  # not sure about this...
  foreach(depends ${EXPORT_BOOST_DEPENDS})
    list(FIND Boost_CATALOG ${depends} index)
    if(index EQUAL "-1")
      message(WARNING "unknown Boost component: ${depends}")
    else()
      math(EXPR package_index "${index} + 1")
      math(EXPR version_index "${index} + 2")
      list(GET Boost_CATALOG ${package_index} package)
      list(GET Boost_CATALOG ${version_index} version)
      list(APPEND EXPORT_DEPENDS "${package} ${version}")
    endif()
  endforeach(depends)

  foreach(depends ${EXPORT_DEPENDS})
    string(FIND ${depends} " " index)
    string(SUBSTRING ${depends} 0 ${index} name)
    set(_find_package "${_find_package}find_package(${depends})\n")
    set(_definitions  "${_definitions}\${${name}_DEFINITIONS}\n  ")
    set(_include_dirs "${_include_dirs}\${${name}_INCLUDE_DIRS}\n  ")
    set(_libraries    "${_libraries}\${${name}_LIBRARIES}\n  ")
  endforeach(depends)

  foreach(path ${EXPORT_INCLUDE_DIRECTORIES})
    get_filename_component(path "${path}" ABSOLUTE)
    set(_include_dirs "${_include_dirs}\"${path}/\"\n  ")
  endforeach(path)

  set(libraries)
  set(executables)
  foreach(target ${EXPORT_TARGETS})
    get_target_property(type ${target} TYPE)
    if(type STREQUAL "SHARED_LIBRARY" OR type STREQUAL "STATIC_LIBRARY")
      if(type STREQUAL "SHARED_LIBRARY")
        set(_libraries    "${_libraries}${target}\n  ")
      endif(type STREQUAL "SHARED_LIBRARY")
      list(APPEND libraries ${target})
    elseif(type STREQUAL "EXECUTABLE")
      list(APPEND executables ${target})
    endif()
  endforeach(target)

  set(_include_guard "__${PROJECT_NAME}Config_included")
  set(_export_file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake")

  file(WRITE "${_export_file}"
    "# Generated by Boost.CMake\n\n"
    "if(${_include_guard})\n"
    "  return()\n"
    "endif(${_include_guard})\n"
    "set(${_include_guard} TRUE)\n\n"
    )

  if(_find_package)
    file(APPEND "${_export_file}"
      "${_find_package}\n"
      )
  endif(_find_package)

  if(_definitions)
    file(APPEND "${_export_file}"
      "set(${PROJECT_NAME}_DEFINITIONS\n  ${_definitions})\n\n"
      )
  endif(_definitions)

  if(_include_dirs)
    install(DIRECTORY ${_include_dirs}
      DESTINATION include
      COMPONENT "${BOOST_DEVELOP_COMPONENT}"
      CONFIGURATIONS "Release"
      )
    file(APPEND "${_export_file}"
      "set(${PROJECT_NAME}_INCLUDE_DIRS\n  ${_include_dirs})\n\n"
      )
  endif(_include_dirs)

  if(_libraries)
    file(APPEND "${_export_file}"
      "set(${PROJECT_NAME}_LIBRARIES\n  ${_libraries})\n\n"
      )
  endif(_libraries)

  foreach(code ${EXPORT_CODE})
    file(APPEND "${_export_file}" "${code}")
  endforeach(code)

  # TODO: [NAMELINK_ONLY|NAMELINK_SKIP]
  install(TARGETS ${libraries} ${executables}
    ARCHIVE
      DESTINATION lib
      COMPONENT "${BOOST_DEVELOP_COMPONENT}"
      CONFIGURATIONS "Release"
    LIBRARY
      DESTINATION lib
      COMPONENT "${BOOST_RUNTIME_COMPONENT}"
      CONFIGURATIONS "Release"
    RUNTIME
      DESTINATION bin
      COMPONENT "${BOOST_RUNTIME_COMPONENT}"
      CONFIGURATIONS "Release"
    )
  install(TARGETS ${libraries}
    ARCHIVE
      DESTINATION lib
      COMPONENT "${BOOST_DEBUG_COMPONENT}"
      CONFIGURATIONS "Debug"
    LIBRARY
      DESTINATION lib
      COMPONENT "${BOOST_DEBUG_COMPONENT}"
      CONFIGURATIONS "Debug"
    RUNTIME
      DESTINATION bin
      COMPONENT "${BOOST_DEBUG_COMPONENT}"
      CONFIGURATIONS "Debug"
    )

  export(PACKAGE ${PROJECT_NAME})
endfunction(boost_export)
