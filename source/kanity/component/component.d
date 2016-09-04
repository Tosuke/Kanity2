module kanity.component.component;

import kanity.imports;
import kanity.object.data;

abstract class KanityComponent{
  void initialize(){}
  void update(){}
  void finalize(){}

  //abstract void send(in string operation, KanityData[] args);
}
