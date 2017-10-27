/*! ******************************************************************************
 *
 * Pentaho Big Data
 *
 * Copyright (C) 2002-2017 by Hitachi Vantara : http://www.pentaho.com
 *
 *******************************************************************************
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 ******************************************************************************/
package org.pentaho.hadoop.mapreduce;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.mapreduce.Cluster;
import org.apache.hadoop.mapreduce.QueueAclsInfo;
import org.apache.hadoop.security.UserGroupInformation;
import org.apache.hadoop.yarn.api.records.QueueACL;
import org.pentaho.di.i18n.BaseMessages;

import java.io.IOException;
import java.util.Arrays;
import java.util.function.Predicate;

public class YarnQueueAclsVerifier {
  public static boolean verify( QueueAclsInfo[] queueAclsInfos ) throws IOException, InterruptedException {
    return queueAclsInfos != null && Arrays.stream( queueAclsInfos ).map( QueueAclsInfo::getOperations )
      .flatMap( Arrays::stream ).anyMatch( Predicate.isEqual( QueueACL.SUBMIT_APPLICATIONS.toString() ) );
  }

  public static void verify() {

    QueueAclsInfo[] queueAclsInfos;
    Thread currentThread = Thread.currentThread();
    ClassLoader contextClassLoader = currentThread.getContextClassLoader();

    try {
      currentThread.setContextClassLoader( YarnQueueAclsVerifier.class.getClassLoader() );

      queueAclsInfos = createClusterDescription( new Configuration() ).getQueueAclsForCurrentUser();
      if ( !verify( queueAclsInfos ) ) {
        throw new YarnQueueAclsException( BaseMessages.getString( YarnQueueAclsVerifier.class,
          "YarnQueueAclsVerifier.UserHasNoPermissions", UserGroupInformation.getCurrentUser().getUserName() ) );
      }
    } catch ( IOException e ) {
      e.printStackTrace();
    } catch ( InterruptedException e ) {
      e.printStackTrace();
    } finally {
      // Cleaning up after call is made
      currentThread.setContextClassLoader( contextClassLoader );
    }
    //return false;
  }

  private static Cluster createClusterDescription( org.apache.hadoop.conf.Configuration configuration )
    throws IOException {
    return new Cluster( configuration );
  }

}
