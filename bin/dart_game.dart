import 'dart:io';
import 'dart:math';

// ====== 추상 클래스 ======
abstract class Unit {
  String name;
  int health;
  int attack;
  int defense;

  Unit(this.name, this.health, this.attack, this.defense);

  bool get isAlive => health > 0;

  void showStatus();
}

// ====== 캐릭터 클래스 ======
class Character extends Unit {
  bool itemUsed = false;
  int baseAttack;

  Character(super.name, super.health, super.attack, super.defense)
    : baseAttack = attack;

  void attackMonster(Monster monster) {
    int damage = max(1, attack - monster.defense);
    monster.health -= damage;
    print('$name의 공격! ${monster.name}에게 $damage 데미지');
  }

  void defend(int monsterDamage) {
    health += monsterDamage;
    print('$name가 방어! 몬스터가 입힌 데미지만큼 체력 $monsterDamage 회복');
  }

  void useItem() {
    if (!itemUsed) {
      attack *= 2;
      itemUsed = true;
      print('$name가 아이템을 사용! 이번 턴 공격력 2배');
    } else {
      print('이미 아이템을 사용했습니다.');
    }
  }

  void resetItem() {
    if (itemUsed) {
      attack = baseAttack;
      itemUsed = false;
    }
  }

  @override
  void showStatus() {
    print('[$name] 체력:$health  공격력:$attack  방어력:$defense');
  }
}

// ====== 몬스터 클래스 ======
class Monster extends Unit {
  int maxAttack;
  int turnCount = 0;

  Monster(String name, int health, this.maxAttack, int defense)
    : super(name, health, 0, defense);

  void setRandomAttack(int minDefense) {
    int range = maxAttack - minDefense + 1;
    if (range <= 0) {
      attack = minDefense;
    } else {
      attack = minDefense + Random().nextInt(range);
    }
  }

  void attackCharacter(Character character) {
    int damage = max(1, attack - character.defense);
    character.health -= damage;
    print('$name의 공격! ${character.name}에게 $damage 데미지');
  }

  void increaseDefense() {
    defense += 2;
    print('$name의 방어력이 증가했습니다! 현재 방어력: $defense');
  }

  @override
  void showStatus() {
    print('[$name] 체력:$health  최대공격력:$maxAttack  방어력:$defense');
  }
}

// ====== 게임 클래스 ======
class Game {
  late List<Character> party; // 캐릭터 1명 리스트
  late Character currentCharacter; // 현재 캐릭터
  late List<Monster> monsters;
  int monstersDefeated = 0;

  void startGame() {
    print('==== 1인용 RPG 게임을 시작합니다 ====');
    loadParty();
    loadMonsters();

    currentCharacter = party.first;

    while (currentCharacter.isAlive && monsters.isNotEmpty) {
      // 무작위 이벤트 발생
      triggerRandomEvent();

      Monster monster = getRandomMonster();
      print('\n=== 새로운 빌런 등장! ===');
      monster.showStatus();

      // ignore: unused_local_variable
      int turn = 0;
      monster.turnCount = 0;

      while (currentCharacter.isAlive && monster.isAlive) {
        turn++;
        monster.turnCount++;
        print('\n--- 현재 상태 ---');
        showPartyStatus();
        monster.showStatus();

        int action = getAction();
        currentCharacter.resetItem();

        if (action == 1) {
          currentCharacter.attackMonster(monster);
        } else if (action == 2) {
          print('${currentCharacter.name}가 방어를 선택!');
        } else if (action == 3) {
          currentCharacter.useItem();
          currentCharacter.attackMonster(monster);
        }

        monster.setRandomAttack(currentCharacter.defense);

        if (monster.isAlive) {
          if (action == 2) {
            int damage = max(1, monster.attack - currentCharacter.defense);
            currentCharacter.defend(damage);
          } else {
            monster.attackCharacter(currentCharacter);
          }
        }

        if (monster.turnCount % 3 == 0) {
          monster.increaseDefense();
        }

        if (!currentCharacter.isAlive) {
          print('\n${currentCharacter.name}가 쓰러졌습니다!');
          print('게임 오버!');
          saveGameResult();
          return;
        }
        if (!monster.isAlive) {
          print('\n${monster.name}를 물리쳤습니다!');
          monstersDefeated++;
          monsters.remove(monster);

          if (monsters.isEmpty) {
            print('\n축하합니다! 모든 빌런을 물리쳤습니다!');
            saveGameResult();
            return;
          } else {
            if (!askNextBattle()) {
              print('게임을 종료합니다.');
              saveGameResult();
              return;
            }
            break;
          }
        }
      }
    }
  }

  void saveGameResult() {
    final file = File('game_result.txt');
    final sink = file.openWrite(mode: FileMode.writeOnlyAppend);
    sink.writeln('게임 결과 (${DateTime.now()})');
    sink.writeln('==============');
    sink.writeln('몬스터 처치 수: $monstersDefeated');
    sink.writeln('캐릭터 상태:');
    for (var c in party) {
      sink.writeln(
        '이름: ${c.name}, 체력: ${c.health}, 공격력: ${c.attack}, 방어력: ${c.defense}',
      );
    }
    sink.writeln('==============\n');
    sink.close();
    print('게임 결과가 game_result.txt에 저장되었습니다.');
  }

  void triggerRandomEvent() {
    print('\n[이벤트 발생]');
    Character target = currentCharacter;
    final rand = Random().nextDouble();
    if (rand < 0.25) {
      int heal = 10 + Random().nextInt(11);
      target.health += heal;
      print('회복의 샘을 발견! ${target.name}의 체력이 $heal 회복되었습니다.');
    } else if (rand < 0.45) {
      int damage = 5 + Random().nextInt(6);
      target.health -= damage;
      print('함정에 빠졌습니다! ${target.name}의 체력이 $damage 감소했습니다.');
      if (target.health <= 0) {
        target.health = 0;
        print('${target.name}가 쓰러졌습니다...');
      }
    } else if (rand < 0.65) {
      int rewardType = Random().nextInt(2);
      if (rewardType == 0) {
        target.attack += 2;
        print('신비한 상자를 열어 ${target.name}의 공격력이 2 상승했습니다!');
      } else {
        target.defense += 2;
        print('신비한 상자를 열어 ${target.name}의 방어력이 2 상승했습니다!');
      }
    } else if (rand < 0.80) {
      print('수상한 상인을 만났습니다. 아이템(공격력 2배, 1회용)을 5 체력과 교환하시겠습니까? (y/n)');
      String? input = stdin.readLineSync();
      if (input != null && input.toLowerCase() == 'y') {
        if (target.health > 5) {
          target.health -= 5;
          target.itemUsed = false;
          print('아이템을 획득했습니다! (이번 전투 중 한 번 사용 가능)');
        } else {
          print('체력이 부족하여 거래할 수 없습니다.');
        }
      } else {
        print('상인을 무시하고 지나갑니다.');
      }
    } else {
      int heal = 5 + Random().nextInt(6);
      target.health += heal;
      print('잠시 휴식을 취해 ${target.name}의 체력이 $heal 회복되었습니다.');
    }
  }

  void showPartyStatus() {
    print('--- 캐릭터 상태 ---');
    for (var c in party) {
      c.showStatus();
    }
    print('현재 전투 중: ${currentCharacter.name}');
  }

  void loadParty() {
    party = [];
    print('캐릭터를 1명 생성합니다.');
    print('\n캐릭터 이름을 입력하세요(한글/영문만):');
    String name = getCharacterName();

    // 능력치 랜덤 배정 (조정된 범위)
    int health = 80 + Random().nextInt(41); // 80~120
    int attack = 20 + Random().nextInt(16); // 20~35
    int defense = 8 + Random().nextInt(11); // 8~18

    print('\n[랜덤 능력치 배정]');
    print('체력: $health, 공격력: $attack, 방어력: $defense');

    party.add(Character(name, health, attack, defense));
  }

  void loadMonsters() {
    try {
      final file = File('monsters.txt');
      final lines = file.readAsLinesSync();
      monsters = [];
      int monsterCount = Random().nextInt(4) + 2; // 2~5마리 랜덤
      int count = 0;
      for (final line in lines) {
        if (count >= monsterCount) break;
        final name = line.trim();
        if (name.isEmpty) continue;
        int health = 50 + Random().nextInt(51); // 50~100
        int maxAttack = 18 + Random().nextInt(15); // 18~32
        int defense = 5 + Random().nextInt(11); // 5~15
        monsters.add(Monster(name, health, maxAttack, defense));
        count++;
        print('[빌런 생성] $name - 체력:$health, 최대공격력:$maxAttack, 방어력:$defense');
      }
      if (monsters.length < 2) throw FormatException('빌런이 2명 미만입니다.');
      print('\n이번 게임의 빌런 수: $monsterCount명');
    } catch (e) {
      print('몬스터 데이터를 불러오는 데 실패했습니다: $e');
      exit(1);
    }
  }

  Monster getRandomMonster() {
    return monsters[Random().nextInt(monsters.length)];
  }

  int getAction() {
    while (true) {
      stdout.write('행동 선택: 공격(1), 방어(2), 아이템(3) > ');
      String? input = stdin.readLineSync();
      if (input == '1' || input == '2' || input == '3') {
        return int.parse(input!);
      }
      print('잘못된 입력입니다. 1~3 중 하나를 입력하세요.');
    }
  }

  String getCharacterName() {
    while (true) {
      stdout.write('> ');
      String? name = stdin.readLineSync();
      if (name != null &&
          name.isNotEmpty &&
          RegExp(r'^[a-zA-Z가-힣]+$').hasMatch(name)) {
        return name;
      }
      print('이름은 한글/영문만 가능합니다.');
    }
  }

  bool askNextBattle() {
    while (true) {
      stdout.write('다음 빌런과 대결하시겠습니까? (y/n): ');
      String? input = stdin.readLineSync();
      if (input == null) continue;
      if (input.toLowerCase() == 'y') return true;
      if (input.toLowerCase() == 'n') return false;
      print('y 또는 n만 입력하세요.');
    }
  }
}

void main() {
  Game game = Game();
  game.startGame();
}
